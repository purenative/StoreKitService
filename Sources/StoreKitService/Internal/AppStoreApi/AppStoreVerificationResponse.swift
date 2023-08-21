import Foundation

struct AppStoreVerificationResponse: Codable {
    
    let latestReceiptInfo: [InApp]?
    let receipt: Receipt?
    let status: Int
    
    enum CodingKeys: String, CodingKey {
        
        case latestReceiptInfo = "latest_receipt_info"
        case receipt
        case status
        
    }
    
}
