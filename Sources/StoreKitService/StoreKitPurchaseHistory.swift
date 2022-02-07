import StoreKit

final class StoreKitPurchaseHistory {
    
    private let CHECK_SANDBOX_STATUS_CODE = 21007
    private let VERIFICATION_STORAGE_KEY = "StoreKitPurchaseHistory_verificationStorageKey"
    
    private let password: String
    
    init(password: String) {
        self.password = password
    }
    
    func getReceiptString() throws -> String? {
        guard let appStoreReceiptURL = Bundle.main.appStoreReceiptURL,
              FileManager.default.fileExists(atPath: appStoreReceiptURL.path) else {
                  return nil
              }
        
        let receiptData = try Data(contentsOf: appStoreReceiptURL,
                                   options: .alwaysMapped)
        
        let receiptString = receiptData.base64EncodedString(options: [])
        
        return receiptString
    }
    
    func refreshHistory() async throws {
        guard let receiptString = try getReceiptString() else {
            #if DEBUG
            print("StoreKitPurchaseHistory: receipt is empty")
            #endif
            return
        }
        let receiptData = ReceiptData(receiptData: receiptString,
                                      password: password,
                                      excludeOldTransactions: true)
        let verificationResponse = try await verifyReceipt(receiptData: receiptData)
        setVerificationResponse(verificationResponse)
    }
    
    func isSubscriptionActive(for product: StoreKitProduct) -> Bool {
        guard let lastVerificationResponse = getStoredVerificationResponse() else {
            return false
        }
        let currentTime = Date().timeIntervalSince1970 * 1_000
        let lastReceiptInfos = lastVerificationResponse.latestReceiptInfo?.filter {
            $0.productID == product.product.productIdentifier &&
            $0.expiresDateTimeStamp > currentTime
        } ?? []
        return lastReceiptInfos.count > 0
    }
    
}

private extension StoreKitPurchaseHistory {
    
    func getStoredVerificationResponse() -> AppStoreVerificationResponse? {
        guard let data = UserDefaults.standard.data(forKey: VERIFICATION_STORAGE_KEY),
              let decoded = try? JSONDecoder().decode(AppStoreVerificationResponse.self, from: data) else {
                  return nil
              }
        return decoded
    }
    
    func setVerificationResponse(_ verificationResponse: AppStoreVerificationResponse?) {
        guard let verificationResponse = verificationResponse,
              let encoded = try? JSONEncoder().encode(verificationResponse) else {
                  return
              }
        UserDefaults.standard.set(encoded, forKey: VERIFICATION_STORAGE_KEY)
    }
    
    func verifyReceipt(verificationMode: VerificationMode = .production,
                       receiptData: ReceiptData) async throws -> AppStoreVerificationResponse {
        
        var urlRequest = URLRequest(url: verificationMode.verificationURL)
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = try? JSONEncoder().encode(receiptData)
        
        let requestTask = RequestTask(urlRequest: urlRequest)
        let (data, _) = try await requestTask.run()
        
        let verificationResponse = try JSONDecoder().decode(AppStoreVerificationResponse.self,
                                                            from: data)
        
        switch verificationMode {
        case .production:
            if verificationResponse.status == CHECK_SANDBOX_STATUS_CODE {
                return try await verifyReceipt(verificationMode: .sandbox,
                                               receiptData: receiptData)
            } else {
                fallthrough
            }
            
        case .sandbox:
            return verificationResponse
        }
    }
    
}
class RequestTask {
    
    private var task: URLSessionTask?
    
    let urlRequest: URLRequest
    
    init(urlRequest: URLRequest) {
        self.urlRequest = urlRequest
    }
    
    func run(in session: URLSession = .shared) async throws -> (Data, URLResponse) {
        try await withCheckedThrowingContinuation { continuation in
            run(in: session) { data, response, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let data = data,
                          let response = response {
                    let result = (data, response)
                    continuation.resume(returning: result)
                }
            }
        }
    }
    
    private func run(in session: URLSession,
                     onCompleted: @escaping (Data?, URLResponse?, Error?) -> Void) {
        
        task = session.dataTask(with: urlRequest) { data, response, error in
            onCompleted(data, response, error)
        }
        task?.resume()
    }
    
}

struct ReceiptData: Codable {
    
    let receiptData: String
    let password: String
    let excludeOldTransactions: Bool
    
    init(receiptData: String,
         password: String,
         excludeOldTransactions: Bool) {
        
        self.receiptData = receiptData
        self.password = password
        self.excludeOldTransactions = excludeOldTransactions
    }
    
    enum CodingKeys: String, CodingKey {
        case receiptData = "receipt-data"
        case password
        case excludeOldTransactions = "exclude-old-transactions"
    }
    
}

enum VerificationMode {
    
    private static let SANDBOX_VERIFICATION_URL_STRING = "https://sandbox.itunes.apple.com/verifyReceipt"
    private static let PRODUCTION_VERIFICATION_URL_STRING = "https://buy.itunes.apple.com/verifyReceipt"
    
    case sandbox
    case production
    
    var verificationURL: URL {
        switch self {
        case .sandbox:
            return URL(string: VerificationMode.SANDBOX_VERIFICATION_URL_STRING)!
            
        case .production:
            return URL(string: VerificationMode.PRODUCTION_VERIFICATION_URL_STRING)!
        }
    }
    
}
