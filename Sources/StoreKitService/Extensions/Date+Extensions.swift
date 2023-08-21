import Foundation

extension Date {
    
    init(millisecondsSince1970: Int) {
        let timeIntervalSince1970 = TimeInterval(millisecondsSince1970) / 1_000
        self.init(timeIntervalSince1970: timeIntervalSince1970)
    }
    
}
