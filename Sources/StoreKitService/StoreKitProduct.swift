import StoreKit

public final class StoreKitProduct {
    public let product: SKProduct
    
    private(set) var isSubscriptionActive: Bool = false
       
    public var localizedPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = product.priceLocale
        return formatter.string(from: product.price) ?? "-"
    }
    
    public var name: String {
        product.localizedTitle
    }
    
    public var periodName: String {
        switch product.subscriptionPeriod?.unit {
        case .day:
            if product.subscriptionPeriod?.numberOfUnits == 7 {
                return SKProduct.PeriodUnit.week.description
            }
            fallthrough
            
        default:
            return product.subscriptionPeriod?.unit.description ?? ""
        }
    }
    
    public init(product: SKProduct) {
        self.product = product
    }
    
    public func markAsActiveSubscription(_ active: Bool) {
        self.isSubscriptionActive = active
    }
    
}

extension StoreKitProduct: CustomStringConvertible {
    
    public var description: String {
        "Product \"\(product.localizedTitle)\" (\(product.productIdentifier)), price: \(localizedPrice)"
    }
    
}
