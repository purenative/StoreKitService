import Foundation
import StoreKit

public final class SKHistoryService {
    
    private static let checkSandboxStatusCode = 21007
    private static let verificationStorageKey = "SKHistoryService_verificationStorageKey"
    
    private let masterSharedKey: String
    
    @Published
    public private(set) var latestPurchaseRecords: [SKPurchaseRecord] = []
    
    @Published
    public private(set) var allInAppRecords: [SKPurchaseRecord] = []
    
    public init(masterSharedKey: String) {
        self.masterSharedKey = masterSharedKey
    }
    
    @MainActor
    public func refresh() async {
        let verificationResponse = await getLatestVerificationResponse()
        
        guard let verificationResponse else {
            return
        }
        
        let latestUserInApps = verificationResponse.latestReceiptInfo ?? []
        latestPurchaseRecords = latestUserInApps.map(SKPurchaseRecord.init).sorted().reversed()
        
        allInAppRecords = verificationResponse.receipt?.inApp?.map(SKPurchaseRecord.init).sorted().reversed() ?? []
    }
    
    public func requestReceiptString() -> String? {
        guard let appStoreReceiptURL = Bundle.main.appStoreReceiptURL else {
            return nil
        }
        
        do {
            let receiptData = try Data(
                contentsOf: appStoreReceiptURL,
                options: .alwaysMapped
            )
            return receiptData.base64EncodedString()
        } catch {
            return nil
        }
    }
    
    public func isSubscriptionActive(productIdentifier: String) -> Bool {
        let now = Date()
        
        let record = latestPurchaseRecords.first {
            $0.productID == productIdentifier &&
            $0.purchaseDate...$0.expiresDate ~= now
        }
        
        return record != nil
    }
    
    public func isProductAlreadyPurchased(productIdentifier: String) -> Bool {
        let record = allInAppRecords.first {
            $0.productID == productIdentifier
        }
        
        return record != nil
    }
    
}

private extension SKHistoryService {
    
    func requestVerificationResponse(body: AppStoreReceiptVerificationBody, environment: AppStoreVerificationEnvironment) async throws -> AppStoreVerificationResponse {
        var request = URLRequest(url: environment.verificationURL)
        request.httpMethod = "POST"
        request.httpBody = try? JSONEncoder().encode(body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(
            AppStoreVerificationResponse.self,
            from: data
        )
        
        switch environment {
        case .production:
            if response.status == SKHistoryService.checkSandboxStatusCode {
                return try await requestVerificationResponse(
                    body: body,
                    environment: .sandbox
                )
            }
            fallthrough
            
        case .sandbox:
            return response
        }
    }
    
    func getLatestVerificationResponse() async -> AppStoreVerificationResponse? {
        guard let receiptString = requestReceiptString() else {
            return nil
        }
        
        let body = AppStoreReceiptVerificationBody(
            receiptData: receiptString,
            password: masterSharedKey,
            excludeOldTransactions: true
        )
        do {
            let verificationResponse = try await requestVerificationResponse(
                body: body,
                environment: .production
            )
            setVerificationResponse(verificationResponse)
            return verificationResponse
        } catch {
            return getStoredVerificationResponse()
        }
    }
    
    func getStoredVerificationResponse() -> AppStoreVerificationResponse? {
        guard let data = UserDefaults.standard.data(forKey: SKHistoryService.verificationStorageKey) else {
            return nil
        }
        let decoded = try? JSONDecoder().decode(
            AppStoreVerificationResponse.self,
            from: data
        )
        return decoded
    }
    
    func setVerificationResponse(_ verificationResponse: AppStoreVerificationResponse?) {
        guard let verificationResponse else {
            return
        }
        let encoded = try? JSONEncoder().encode(verificationResponse)
        UserDefaults.standard.set(encoded, forKey: SKHistoryService.verificationStorageKey)
    }
    
}
