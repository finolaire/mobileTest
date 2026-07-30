import UIKit

extension UIColor {
    
    /// Initialize UIColor with hex integer (e.g. 0xFFFFFF)
    /// - Parameters:
    ///   - hex: Hex integer value (e.g. 0xFFFFFF)
    ///   - alpha: Alpha value (default is 1.0)
    convenience init(hex: Int, alpha: CGFloat = 1.0) {
        let red = CGFloat((hex >> 16) & 0xFF) / 255.0
        let green = CGFloat((hex >> 8) & 0xFF) / 255.0
        let blue = CGFloat(hex & 0xFF) / 255.0
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
    
    /// Initialize UIColor with hex string (e.g. "#FFFFFF" or "FFFFFF")
    /// - Parameters:
    ///   - hexString: Hex string (e.g. "#FFFFFF" or "FFFFFF")
    ///   - alpha: Alpha value (default is 1.0)
    convenience init(hexString: String, alpha: CGFloat = 1.0) {
        var hex = hexString.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        if hex.hasPrefix("#") {
            hex.remove(at: hex.startIndex)
        }
        
        // Handle 0x prefix if present in string
        if hex.hasPrefix("0X") {
            hex.removeFirst(2)
        }

        guard hex.count == 6 else {
            // Return clear color or a default color if format is invalid
            self.init(white: 0, alpha: 0) 
            return
        }

        var rgbValue: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&rgbValue)

        self.init(hex: Int(rgbValue), alpha: alpha)
    }
}
