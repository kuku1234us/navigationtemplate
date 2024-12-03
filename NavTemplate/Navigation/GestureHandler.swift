// GestureHandler.swift

import SwiftUI

protocol GestureHandler {
    var widget: any Widget { get }
    var debugText: String { get }
    var translation: CGPoint { get }
    
    func makeGesture() -> AnyGesture<()>
    func shouldHandleGesture(translation: CGPoint) -> Bool
}

// Default implementation
extension GestureHandler {
    var debugText: String { "" }
    var translation: CGPoint { .zero }
}

extension CGPoint {
    static func + (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }
}
