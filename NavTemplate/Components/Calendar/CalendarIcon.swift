import SwiftUI

struct CalendarIcon: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Move to the starting point
        path.move(to: CGPoint(x: 1650, y: 4949))
        
        // Add the rest of the path points and curves
        path.addCurve(to: CGPoint(x: 1567, y: 4695),
                      control1: CGPoint(x: 1621, y: 4937),
                      control2: CGPoint(x: 1598, y: 4881))
        path.addCurve(to: CGPoint(x: 1252, y: 4754),
                      control1: CGPoint(x: 1532, y: 4532),
                      control2: CGPoint(x: 1458, y: 4654))
        path.addLine(to: CGPoint(x: 1252, y: 4754))
        
        // Add more path operations derived from the SVG's path data
        path.addCurve(to: CGPoint(x: 940, y: 3156),
                      control1: CGPoint(x: 1150, y: 4000),
                      control2: CGPoint(x: 1010, y: 3500))
        
        // Additional move, line, and curve operations to construct the full path
        path.addCurve(to: CGPoint(x: 3810, y: 1961),
                      control1: CGPoint(x: 2650, y: 3000),
                      control2: CGPoint(x: 3400, y: 2400))
        path.addLine(to: CGPoint(x: 1970, y: 1079))
        
        // Close the shape if required
        path.closeSubpath()

        return path
    }
}

// Helper for point multiplication
extension CGPoint {
    static func * (point: CGPoint, scale: CGFloat) -> CGPoint {
        return CGPoint(x: point.x * scale, y: point.y * scale)
    }
} 