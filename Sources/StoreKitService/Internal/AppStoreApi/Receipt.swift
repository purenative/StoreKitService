import Foundation

struct Receipt: Codable {
    
    let inApp: [InApp]?
    
    enum CodingKeys: String, CodingKey {
        
        case inApp = "in_app"
        
    }
    
}
