import Foundation
import StoreKit

extension SKPaymentTransactionState: CustomStringConvertible {
    
    public var description: String {
        switch self {
        case .purchasing:
            return "purchasing"
            
        case .purchased:
            return "purchased"
            
        case .failed:
            return "failed"
            
        case .restored:
            return "restored"
            
        case .deferred:
            return "deferred"
            
        @unknown default:
            return "unknown"
        }
    }
    
}
