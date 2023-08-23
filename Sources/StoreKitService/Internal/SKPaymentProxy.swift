import StoreKit

final class SKPaymentProxy: NSObject {
    
    private let paymentQueue = SKPaymentQueue.default()
    private let target: SKPaymentProxyTarget
    private var continuation: CheckedContinuation<Bool, Never>!
    
    init(target: SKPaymentProxyTarget) {
        self.target = target
    }
    
    @MainActor
    func process() async -> Bool {
        return await withCheckedContinuation { continuation in
            self.continuation = continuation
            self.enqueuePayment()
        }
    }
    
}

// MARK: - SKPaymentTransactionObserver
extension SKPaymentProxy: SKPaymentTransactionObserver {
    
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        #if DEBUG
        print("STOREKITSERVICE: Transactions updated for target", target)
        #endif
        
        switch target {
        case .purchase:
            for transaction in transactions {
                processPaymentTransaction(transaction)
            }
            
        case .restoreTransactions, .redeemCode:
            processRestoredPaymentTransactions(transactions)
        }
    }
    
}

private extension SKPaymentProxy {
    
    func enqueuePayment() {
        paymentQueue.add(self)
        
        #if DEBUG
        print("STOREKITSERVICE: Enqueued payment with target:", target)
        #endif

        switch target {
        case let .purchase(product, applicationUsername):
            let payment = SKMutablePayment(product: product)
            payment.applicationUsername = applicationUsername
            paymentQueue.add(payment)
            
        case let .restoreTransactions(applicationUsername):
            paymentQueue.restoreCompletedTransactions(withApplicationUsername: applicationUsername)
            
        case .redeemCode:
            paymentQueue.presentCodeRedemptionSheet()
        }
    }
    
    func processPaymentTransaction(_ transaction: SKPaymentTransaction) {
        #if DEBUG
        print("STOREKITSERVICE: Product identifier:", transaction.payment.productIdentifier)
        print("STOREKITSERVICE: Transaction state:", transaction.transactionState)
        print("STOREKITSERVICE: Application username:", transaction.payment.applicationUsername ?? "-")
        print("STOREKITSERVICE:", String(repeating: "-", count: 10))
        #endif
        
        guard transaction.transactionState != .deferred && transaction.transactionState != .purchasing else {
            return
        }
        guard case let .purchase(product, _) = target else {
            return
        }
        guard product.productIdentifier == transaction.payment.productIdentifier else {
            return
        }
        
        let purchased = transaction.transactionState == .purchased
        let restored = transaction.transactionState == .restored
        let successed = purchased || restored
        
        completeWithSuccess(
            successed,
            transactions: [transaction]
        )
    }
    
    func processRestoredPaymentTransactions(_ transactions: [SKPaymentTransaction]) {
        #if DEBUG
        for transaction in transactions {
            print("STOREKITSERVICE: Product identifier:", transaction.payment.productIdentifier)
            print("STOREKITSERVICE: Transaction state:", transaction.transactionState)
            print("STOREKITSERVICE: Application username:", transaction.payment.applicationUsername ?? "-")
            print("STOREKITSERVICE:", String(repeating: "-", count: 10))
        }
        #endif
        
        completeWithSuccess(
            true,
            transactions: transactions
        )
    }
    
    func completeWithSuccess(_ success: Bool, transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            paymentQueue.finishTransaction(transaction)
        }
        paymentQueue.remove(self)
        
        continuation?.resume(returning: success)
        continuation = nil
    }
    
}
