import Foundation

struct InApp: Codable, Hashable, Equatable {
    
    let transactionID: String
    let productID: String
    let subscriptionGroupIdentifier: String?
    let quantity: String
    let purchaseDateMS: String
    let originalPurchaseDateMS: String
    let expiresDateMS: String
    
    enum CodingKeys: String, CodingKey {
        
        case transactionID = "transaction_id"
        case productID = "product_id"
        case subscriptionGroupIdentifier = "subscription_group_identifier"
        case quantity
        case purchaseDateMS = "purchase_date_ms"
        case originalPurchaseDateMS = "original_purchase_date_ms"
        case expiresDateMS = "expires_date_ms"
        
    }
    
    // MARK: - Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(transactionID)
        hasher.combine(productID)
        hasher.combine(purchaseDateMS)
    }
    
    // MARK: - Equatable
    static func ==(lhs: InApp, rhs: InApp) -> Bool {
        lhs.transactionID == rhs.transactionID
    }
    
}
