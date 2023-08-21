import StoreKit

enum SKPaymentProxyTarget {
    
    case purchase(SKProduct)
    case restoreTransactions
    
}

final class SKPaymentProxy: NSObject, SKPaymentTransactionObserver {
    
    private let target: SKPaymentProxyTarget
    
    private var payment: SKPayment!
    private var continuation: CheckedContinuation<Bool, Never>!
    
    init(target: SKPaymentProxyTarget) {
        self.target = target
    }
    
    @MainActor
    func process() async -> Bool {
        SKPaymentQueue.default().add(self)
        
        if case let .purchase(product) = target {
            self.payment = SKPayment(product: product)
        }
        
        return await withCheckedContinuation { continuation in
            self.continuation = continuation
            self.enqueuePayment()
        }
    }
    
    // MARK: - SKPaymentTransactionObserver
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            if transaction.transactionState != .purchasing {
                processTransaction(transaction)
            }
        }
    }
    
}

private extension SKPaymentProxy {
    
    func enqueuePayment() {
        if let payment {
            SKPaymentQueue.default().add(payment)
        } else {
            SKPaymentQueue.default().restoreCompletedTransactions()
        }
    }
    
    func processTransaction(_ transaction: SKPaymentTransaction) {
        var purchased = false
        var restored = false
        
        switch target {
        case let .purchase(product):
            guard product.productIdentifier == transaction.payment.productIdentifier else {
                return
            }
            purchased = transaction.transactionState == .purchased
            
        case .restoreTransactions:
            restored = transaction.transactionState == .restored
        }
        
        SKPaymentQueue.default().finishTransaction(transaction)
        SKPaymentQueue.default().remove(self)
        
        let successed = purchased || restored
        continuation?.resume(returning: successed)
        continuation = nil
    }
    
}
