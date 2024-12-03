// DragGestureHandler.swift

import SwiftUI

class DragGestureHandler: ObservableObject, GestureHandler {
    private var _widget: any Widget
    var widget: any Widget { _widget }
    
    private let direction: DragDirection
    private let threshold: CGFloat
    private let verticalLimit: CGFloat
    
    @Published private(set) var debugText: String = "No gesture detected"
    @Published private(set) var translation: CGPoint = .zero
    
    enum DragDirection {
        case rightToLeft
        case leftToRight
        
        var description: String {
            switch self {
            case .rightToLeft: return "right to left"
            case .leftToRight: return "left to right"
            }
        }
        
        func meetsThreshold(_ translation: CGFloat, threshold: CGFloat) -> Bool {
            switch self {
            case .rightToLeft: return translation < -threshold
            case .leftToRight: return translation > threshold
            }
        }
    }
    
    init(
        widget: any Widget,
        direction: DragDirection,
        threshold: CGFloat = 50,
        verticalLimit: CGFloat = 30
    ) {
        self._widget = widget
        self.direction = direction
        self.threshold = threshold
        self.verticalLimit = verticalLimit
    }
    
    func shouldHandleGesture(translation: CGPoint) -> Bool {
        let horizontalAmount = translation.x
        let verticalAmount = abs(translation.y)
        
        return direction.meetsThreshold(horizontalAmount, threshold: threshold) 
            && verticalAmount < verticalLimit
    }
    
    func makeGesture() -> AnyGesture<()> {
        print("Creating gesture for direction: \(direction)")
        return AnyGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    print("Drag detected: \(value.translation), widget active: \(self.widget.isActive)")
                    self.translation = CGPoint(
                        x: value.translation.width,
                        y: value.translation.height
                    )
                    
                    if self.widget.isActive && self.direction == .rightToLeft {
                        self.debugText = "Gesture ignored - widget already active"
                        return
                    }
                    
                    if !self.widget.isActive && self.direction == .leftToRight {
                        if value.translation.width > self.threshold {
                            print("Activating widget")
                            self.widget.setActive(true)
                            self.debugText += "\nSHOWING WIDGET!"
                        }
                    } else if self.widget.isActive && self.direction == .rightToLeft {
                        if value.translation.width < -self.threshold {
                            print("Deactivating widget")
                            self.widget.setActive(false)
                            self.debugText += "\nHIDING WIDGET!"
                        }
                    }
                }
                .onEnded { _ in
                    print("Gesture ended")
                    self.debugText += "\nGesture ended"
                }
                .map { _ in () }
        )
    }
    
    func updateWidget(_ widget: any Widget) {
        self._widget = widget
    }
}
