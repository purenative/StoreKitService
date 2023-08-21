import Foundation

struct AppStoreReceiptVerificationBody: Codable {
    
    let receiptData: String
    let password: String
    let excludeOldTransactions: Bool
    
    init(receiptData: String, password: String, excludeOldTransactions: Bool) {
        
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
