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
    
    public func purchase(product: SKProduct) async -> Bool {
        let paymentProxy = SKPaymentProxy(target: .purchase(product))
        return await paymentProxy.process()
    }
    
    public func restorePurchases() async -> Bool {
        let paymentProxy = SKPaymentProxy(target: .restoreTransactions)
        return await paymentProxy.process()
    }
    
}
