// UIUtilities.swift

import SwiftUI

public struct RoundedCorner: Shape {
    public var radius: CGFloat = .infinity
    public var corners: UIRectCorner = .allCorners

    public init(radius: CGFloat = .infinity, corners: UIRectCorner = .allCorners) {
        self.radius = radius
        self.corners = corners
    }

    public func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

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

// MARK: - View Extensions

public extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
    
    func withSafeAreaTop() -> some View {
        self.padding(.top, getSafeAreaTop())
    }
    
    func withSafeAreaBottom() -> some View {
        self.padding(.bottom, getSafeAreaBottom())
    }
    
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

    func withTransparentRoundedTopStyle() -> some View {
        return self
            .backgroundBlur(radius: 10, opaque: true)
            .background(Color("SideSheetBg").opacity(0.2))
            .clipShape(RoundedCorner(radius: 20, corners: [.topLeft, .topRight]))
            .innerShadow(
                shape: RoundedCorner(radius: 20, corners: [.topLeft, .topRight]),
                color: Color.bottomSheetBorderMiddle,
                lineWidth: 1,
                offsetX: 0,
                offsetY: 1,
                blur: 0,
                blendMode: .overlay,
                opacity: 0.2
            )
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

    func topBottomBorders(width: CGFloat = 0.5, opacity: Double = 1) -> some View {
        self.border(
            MeshGradient(
                width: 3, height: 3,
                points: [
                    [0.0,0.0], [0.5,0.0], [1.0,0.0],
                    [0.0,0.5], [0.5,0.5], [1.0,0.5],
                    [0.0,1.0], [0.5,1.0], [1.0,1.0]
                ],
                colors: [
                    Color(.black).opacity(0), Color(.white), .black.opacity(0),
                    Color(.black).opacity(0), .black.opacity(0), .black.opacity(0),
                    Color(.black).opacity(0), Color(.white), .black.opacity(0)
                ]
            )
            .opacity(opacity),
        
            width: width
        )
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

// MARK: - Geometry Utilities

/// A utility function to compute the transformation values (offsetX, offsetY, scaleX) between two CGRects.
public func computeTransform(from rect1: CGRect, to rect2: CGRect) -> (offsetX: CGFloat, offsetY: CGFloat, scaleX: CGFloat) {
    // Compute the scale factor (based on widths of rect1 and rect2)
    let scaleX = rect2.width / rect1.width
    
    // Compute the X and Y offsets
    let offsetX = rect2.midX - rect1.midX
    let offsetY = rect2.midY - rect1.midY
    
    return (offsetX, offsetY, scaleX)
}

/// Computes the X scale factor between two CGRects based on their widths.
public func computeScaleX(from rect1: CGRect, to rect2: CGRect) -> CGFloat {
    if rect1.width == 0 {
        return 1 
    }
    return rect2.width / rect1.width
}

/// Computes the Y scale factor between two CGRects based on their heights.
public func computeScaleY(from rect1: CGRect, to rect2: CGRect) -> CGFloat {
    if rect1.height == 0 {
        return 1 
    }
    return rect2.height / rect1.height
}

/// Computes the horizontal offset needed to align the centers of two CGRects.
public func computeOffsetX(from rect1: CGRect, to rect2: CGRect) -> CGFloat {
    if rect1.width == 0 {
        return 0
    }
    let scale = rect2.width / rect1.width
    let deltaX = (rect1.width * (1 - scale)) / 2
    return rect2.minX - rect1.minX - deltaX
}

/// Computes the vertical offset needed to align the centers of two CGRects.
public func computeOffsetY(from rect1: CGRect, to rect2: CGRect) -> CGFloat {
    if rect1.height == 0 {
        return 0
    }
    let scale = rect2.height / rect1.height
    let deltaY = (rect1.height * (1 - scale)) / 2
    return rect2.minY - rect1.minY - deltaY
}

// MARK: - Private Helper Functions

private func getSafeAreaTop() -> CGFloat {
    let scenes = UIApplication.shared.connectedScenes
    let windowScene = scenes.first as? UIWindowScene
    return windowScene?.windows.first?.safeAreaInsets.top ?? 0
}

private func getSafeAreaBottom() -> CGFloat {
    let scenes = UIApplication.shared.connectedScenes
    let windowScene = scenes.first as? UIWindowScene
    return windowScene?.windows.first?.safeAreaInsets.bottom ?? 0
}

private func getKeyWindow() -> UIWindow? {
    let scenes = UIApplication.shared.connectedScenes
    let windowScene = scenes.first as? UIWindowScene
    return windowScene?.windows.first { $0.isKeyWindow }
}
