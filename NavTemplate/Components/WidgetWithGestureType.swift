// WidgetWithGestureType.swift

import SwiftUI

protocol WidgetWithGestureType: Widget where ID == UUID {
    var gestureWrapper: AnyGesture<Void> { get }
}
