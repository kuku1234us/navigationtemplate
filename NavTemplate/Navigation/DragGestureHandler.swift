// DragGestureHandler.swift

import SwiftUI

class DragGestureHandler: ObservableObject, GestureHandler {
    private var _widget: any Widget
    var widget: any Widget { _widget }
    
    private let direction: DragDirection
    private let threshold: CGFloat
    
    @Published private(set) var debugText: String = "No gesture detected"
    @Published var dragOffset: CGFloat = 0
    @Published private(set) var translation: CGPoint = .zero
    
    enum DragDirection {
        case rightToLeft
        case leftToRight
    }
    
    init(
        widget: any Widget,
        direction: DragDirection,
        threshold: CGFloat = 50
    ) {
        self._widget = widget
        self.direction = direction
        self.threshold = threshold
    }
    
    func shouldHandleGesture(translation: CGPoint) -> Bool {
        let horizontalAmount = translation.x
        
        if direction == .leftToRight {
            return horizontalAmount > threshold
        } else {
            return horizontalAmount < -threshold
        }
    }
    
    func makeGesture() -> AnyGesture<()> {
        return AnyGesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .global)
                .onChanged { value in
                    if isInScrollableArea(value.startLocation) {
                        return false
                    }
                    
                    let sheetWidth = UIScreen.main.bounds.width * 0.85
                    let dragChange = value.translation.width
                    
                    if self.direction == .leftToRight {
                        if !self.widget.isActive && dragChange > 0 {
                            self.widget.setActive(true)
                            self.dragOffset = min(max(0, dragChange), sheetWidth)
                            return true
                        }
                    }
                    
                    return false
                }
                .onEnded { value in
                    let sheetWidth = UIScreen.main.bounds.width * 0.85
                    let dragChange = value.translation.width
                    let threshold = sheetWidth / 2
                    
                    withAnimation(.easeOut(duration: 0.3)) {
                        if self.direction == .leftToRight {
                            if dragChange > threshold {
                                self.dragOffset = sheetWidth
                            } else {
                                self.dragOffset = 0
                                self.widget.setActive(false)
                            }
                        }
                    }
                }
                .map { _ in () }
        )
    }
    
    func updateWidget(_ widget: any Widget) {
        self._widget = widget
    }
}

