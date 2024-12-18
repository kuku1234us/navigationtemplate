// UIUtilities.swift

import SwiftUI

public enum ColorUtilities {
    /// Creates a Color from a hex string
    /// - Parameter hex: Hex string in format "#RRGGBB" or "RRGGBB"
    /// - Returns: SwiftUI Color
    public static func fromHex(_ hex: String) -> Color {
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

public extension Color {
    static let bottomSheetBorderMiddle = LinearGradient(
        gradient: Gradient(stops: [
            .init(color: .white, location: 0),
            .init(color: .clear, location: 0.2)
        ]),
        startPoint: .top,
        endPoint: .bottom
    )
}

public extension View {
    func innerShadow<S: Shape, SS: ShapeStyle>(
        shape: S,
        color: SS,
        lineWidth: CGFloat = 1,
        offsetX: CGFloat = 0,
        offsetY: CGFloat = 0,
        blur: CGFloat = 4,
        blendMode: BlendMode = .normal,
        opacity: Double = 1
    ) -> some View {
        return self.overlay(
            shape
                .stroke(color, lineWidth: lineWidth)
                .blendMode(blendMode)
                .offset(x: offsetX, y: offsetY)
                .blur(radius: blur)
                .mask(shape)
                .opacity(opacity)
        )
    }
}

public struct SafeAreaTop: View {
    public init() {}
    
    public var body: some View {
        return GeometryReader { geometry in
            Color.clear
                .frame(height: UIApplication.shared.keyWindow?.safeAreaInsets.top ?? 0)
        }
    }
}

public extension View {
    func withSafeAreaTop() -> some View {
        return self.padding(.top, UIApplication.shared.keyWindow?.safeAreaInsets.top ?? 0)
    }
    
    func withTransparentCardStyle() -> some View {
        return self
            .backgroundBlur(radius: 10, opaque: true)
            .background(Color("SideSheetBg").opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .innerShadow(shape: RoundedRectangle(cornerRadius: 20), color: Color.bottomSheetBorderMiddle, lineWidth: 1, offsetX: 0, offsetY: 1, blur: 0, blendMode: .overlay, opacity: 0.2)
            .shadow(radius: 10)
    }

    func withTransparentRectangleStyle() -> some View {
        return self
            .backgroundBlur(radius: 10, opaque: true)
            .background(Color("SideSheetBg").opacity(0.2))
            .clipShape(Rectangle())
            .innerShadow(shape: Rectangle(), color: Color.bottomSheetBorderMiddle, lineWidth: 1, offsetX: 0, offsetY: 1, blur: 0, blendMode: .overlay, opacity: 0.2)
            .shadow(radius: 10)
    }

    func withTransparentCardStyle2() -> some View {
        return self
            // .backgroundBlur(radius: 10, opaque: true)
            .background(Color("SideSheetBg").opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .innerShadow(shape: RoundedRectangle(cornerRadius: 20), color: Color.bottomSheetBorderMiddle, lineWidth: 1, offsetX: 0, offsetY: 1, blur: 0, blendMode: .overlay, opacity: 0.5)
            .shadow(radius: 10)
    }


}

extension UIApplication {
    var keyWindow: UIWindow? {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }
}
