// WidgetWithGesture.swift

import SwiftUI

struct WidgetWithGesture<W: Widget, G: Gesture>: WidgetWithGestureType where W.ID == UUID {
    let id: UUID
    let body: AnyView
    let gestureWrapper: AnyGesture<Void>

    init(widget: W, gesture: G) {
        self.id = widget.id
        self.body = AnyView(widget)
        self.gestureWrapper = AnyGesture(gesture.map { _ in })
    }
}
