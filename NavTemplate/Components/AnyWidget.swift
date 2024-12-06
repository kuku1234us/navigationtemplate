// AnyWidget.swift

import SwiftUI

struct AnyWidget: Widget {
    typealias ID = UUID
    let id: UUID
    private let _body: AnyView
    let gestureWrapper: AnyGesture<Void>?

    init<W: Widget>(_ widget: W) where W.ID == UUID {
        self.id = widget.id
        self._body = AnyView(widget)
        if let widgetWithGesture = widget as? any WidgetWithGestureType {
            self.gestureWrapper = widgetWithGesture.gestureWrapper
        } else {
            self.gestureWrapper = nil
        }
    }

    var body: some View {
        _body
    }
}
