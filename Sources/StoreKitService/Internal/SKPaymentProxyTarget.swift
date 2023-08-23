import Foundation
import StoreKit

enum SKPaymentProxyTarget: CustomStringConvertible {
    
    case purchase(SKProduct, applicationUsername: String?)
    case restoreTransactions(applicationUsername: String?)
    case redeemCode
    
    var applicationUsername: String? {
        switch self {
        case let .purchase(_, applicationUsername), let .restoreTransactions(applicationUsername):
            return applicationUsername
            
        default:
            return nil
        }
    }
    
    var description: String {
        switch self {
        case .purchase:
            return "purchase"
            
        case .restoreTransactions:
            return "restore transactions"
            
        case .redeemCode:
            return "redeem code"
        }
    }
    
}
