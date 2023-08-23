import Combine
import StoreKit

public final class SKPurchaseServise: NSObject, ObservableObject {
    
    @Published
    public private(set) var products: [SKProduct] = []
    
    @discardableResult
    public func loadProducts(with identifiers: [String]) async -> [SKProduct] {
        let productRequestProxy = SKProductsRequestProxy()
        products = await productRequestProxy.requestProducts(withProductIdentifiers: identifiers)
        return products
    }
    
    public func purchase(product: SKProduct, applicationUsername: String? = nil) async -> Bool {
        let paymentProxy = SKPaymentProxy(
            target: .purchase(product, applicationUsername: applicationUsername)
        )
        return await paymentProxy.process()
    }
    
    public func restorePurchases(applicationUsername: String? = nil) async -> Bool {
        let paymentProxy = SKPaymentProxy(
            target: .restoreTransactions(applicationUsername: applicationUsername)
        )
        return await paymentProxy.process()
    }
    
    public func redeemCode() async -> Bool {
        let paymentProxy = SKPaymentProxy(target: .redeemCode)
        return await paymentProxy.process()
    }
    
}
