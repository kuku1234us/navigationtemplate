import SwiftUI

enum ColorUtilities {
    /// Creates a Color from a hex string
    /// - Parameter hex: Hex string in format "#RRGGBB" or "RRGGBB"
    /// - Returns: SwiftUI Color
    static func fromHex(_ hex: String) -> Color {
        let hex = hex.trimmingCharacters(in: .alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        
        let r, g, b: Double
        switch hex.count {
        case 3: // RGB (12-bit)
            r = Double((int >> 8) * 17) / 255.0
            g = Double((int >> 4 & 0xF) * 17) / 255.0
            b = Double((int & 0xF) * 17) / 255.0
        case 6: // RGB (24-bit)
            r = Double(int >> 16) / 255.0
            g = Double((int >> 8) & 0xFF) / 255.0
            b = Double(int & 0xFF) / 255.0
        default:
            return Color.black // Invalid hex string
        }
        
        return Color(.sRGB, red: r, green: g, blue: b, opacity: 1)
    }
} 