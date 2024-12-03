// Widget.swift

import SwiftUI

protocol Widget: Identifiable, ObservableObject {
    var id: UUID { get }
    var isActive: Bool { get }
    var view: AnyView { get }
    var gesture: AnyGesture<()>? { get }
    
    func setActive(_ active: Bool)
}

// Base class providing standard implementation
class BaseWidget: ObservableObject, Widget {
    var id: UUID = UUID()
    @Published private(set) var isActive: Bool = false
    
    init() {
        print("BaseWidget init, isActive: \(isActive)")
    }
    
    var view: AnyView {
        fatalError("Must override view")
    }
    
    var gesture: AnyGesture<()>? { nil }
    
    func setActive(_ active: Bool) {
        print("BaseWidget setActive called with: \(active)")
        self.isActive = active
        print("BaseWidget isActive is now: \(self.isActive)")
        objectWillChange.send()  // Explicitly notify observers
    }
}
