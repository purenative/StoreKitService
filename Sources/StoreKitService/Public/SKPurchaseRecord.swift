import Foundation

public struct SKPurchaseRecord: Identifiable, Comparable {
    
    public let transactionID: String
    public let productID: String
    public let quantity: Int
    public let purchaseDate: Date
    public let originalPurchaseDate: Date
    public let expiresDate: Date
    
    init(inApp: InApp) {
        transactionID = inApp.transactionID
        productID = inApp.productID
        quantity = Int(inApp.quantity) ?? 1
        purchaseDate = Date(millisecondsSince1970: Int(inApp.purchaseDateMS) ?? 0)
        originalPurchaseDate = Date(millisecondsSince1970: Int(inApp.originalPurchaseDateMS) ?? 0)
        expiresDate = Date(millisecondsSince1970: Int(inApp.expiresDateMS) ?? 0)
    }
    
    // MARK: - Identifiable
    public var id: String {
        transactionID
    }
    
    // MARK: - Comparable
    public static func <(lhs: SKPurchaseRecord, rhs: SKPurchaseRecord) -> Bool {
        lhs.purchaseDate < rhs.purchaseDate
    }
    
}
