import Combine
import StoreKit

public final class SKPurchaseServise: NSObject, ObservableObject {
    
    private let processor: SKTransactionProcessor?
    
    @Published
    public private(set) var products: [SKProduct] = []
    
    public init(processor: SKTransactionProcessor? = nil) {
        self.processor = processor
        
        super.init()
        
        SKPaymentQueue.default().add(self)
    }
    
    deinit {
        SKPaymentQueue.default().remove(self)
    }
    
    @discardableResult
    public func loadProducts(with identifiers: [String]) async -> [SKProduct] {
        let productRequestProxy = SKProductsRequestProxy()
        products = await productRequestProxy.requestProducts(withProductIdentifiers: identifiers)
        return products
    }
    
    public func purchase(product: SKProduct, applicationUsername: String? = nil) {
        let payment = SKMutablePayment(product: product)
        payment.applicationUsername = applicationUsername
        
        SKPaymentQueue.default()
            .add(payment)
    }
    
    public func restorePurchases(applicationUsername: String? = nil) {
        SKPaymentQueue.default()
            .restoreCompletedTransactions(
                withApplicationUsername: applicationUsername
            )
    }
    
    public func redeemCode() {
        SKPaymentQueue.default()
            .presentCodeRedemptionSheet()
    }
    
}

// MARK: - SKPaymentTransactionObserver
extension SKPurchaseServise: SKPaymentTransactionObserver {
    
    public func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased, .restored, .failed:
                Task {
                    await processTransaction(transaction)
                }
                
            default:
                break
            }
        }
    }
    
    public func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        Task {
            await finishRestoring()
        }
    }
    
    public func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        Task {
            await finishRestoring()
        }
    }
    
    func processTransaction(_ transaction: SKPaymentTransaction) async {
        guard let processor else {
            return
        }
        
        let result = await processor.processTransaction(transaction)
        
        if result == .finish {
            await finishTransaction(transaction)
        }
    }
    
    @MainActor
    func finishTransaction(_ transaction: SKPaymentTransaction) async {
        SKPaymentQueue.default().finishTransaction(transaction)
        
        guard let processor else {
            return
        }
        
        await processor.processFinishedTransaction(transaction)
    }
    
    func finishRestoring() async {
        guard let processor else {
            return
        }
        
        await processor.restoringFinished()
    }
    
}
