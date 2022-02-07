struct AppStoreVerificationResponse: Codable {
    
    let latestReceiptInfo: [LatestReceiptInfo]?
    let status: Int
    
    enum CodingKeys: String, CodingKey {
        
        case latestReceiptInfo = "latest_receipt_info"
        case status
        
    }
    
}

struct LatestReceiptInfo: Codable {
    
    let productID: String
    let subscriptionGroupIdentifier: String
    let expiresDate: String
    let expiresDateMS: String
    let isTrialPeriod: String
    
    var expiresDateTimeStamp: Double {
        Double(expiresDateMS) ?? 0
    }
    
    var isTrialActive: Bool {
        isTrialPeriod.lowercased() == "true"
    }
    
    enum CodingKeys: String, CodingKey {
        
        case productID = "product_id"
        case subscriptionGroupIdentifier = "subscription_group_identifier"
        case expiresDate = "expires_date"
        case expiresDateMS = "expires_date_ms"
        case isTrialPeriod = "is_trial_period"
        
    }
    
}
