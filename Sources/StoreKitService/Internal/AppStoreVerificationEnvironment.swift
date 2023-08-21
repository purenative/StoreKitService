import Foundation

enum AppStoreVerificationEnvironment {
    
    private static let SANDBOX_VERIFICATION_URL_STRING = "https://sandbox.itunes.apple.com/verifyReceipt"
    private static let PRODUCTION_VERIFICATION_URL_STRING = "https://buy.itunes.apple.com/verifyReceipt"
    
    case sandbox
    case production
    
    var verificationURL: URL {
        switch self {
        case .sandbox:
            return URL(string: AppStoreVerificationEnvironment.SANDBOX_VERIFICATION_URL_STRING)!
            
        case .production:
            return URL(string: AppStoreVerificationEnvironment.PRODUCTION_VERIFICATION_URL_STRING)!
        }
    }
    
}
