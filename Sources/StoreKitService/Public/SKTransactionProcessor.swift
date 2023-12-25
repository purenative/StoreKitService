import StoreKit

public enum SKTransactionProcessorResult {
    
    case finish
    case skip
    
}

public protocol SKTransactionProcessor {
    
    func processTransaction(_ transaction: SKPaymentTransaction) async -> SKTransactionProcessorResult
    
    func processFinishedTransaction(_ transaction: SKPaymentTransaction) async
    
    func restoringFinished() async
    
}
