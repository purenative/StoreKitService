import StoreKit

extension SKProduct.PeriodUnit: CustomStringConvertible {
    
    public var description: String {
        switch self {
        case .day:
            return "day"
            
        case .week:
            return "week"
            
        case .month:
            return "month"
            
        case .year:
            return "year"
            
        default:
            return "unknown"
        }
    }
    
}
