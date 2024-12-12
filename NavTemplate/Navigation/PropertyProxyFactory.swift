import SwiftUI

class PropertyProxy: ObservableObject {
    let id: UUID
    @Published var isActive: Bool = false
    @Published var offset: CGFloat = 0
    @Published var isExpanded: Bool = false
    
    // State that doesn't need to trigger view updates
    var directionChecked: Bool = false
    var prevDragChange: CGFloat = 0
    var lastDragDirection: DragGestureHandler.DragDirection?
    
    init(id: UUID, initialOffset: CGFloat) {
        self.id = id
        self.offset = initialOffset
    }
}

class PropertyProxyFactory {
    static let shared = PropertyProxyFactory()
    private var proxies: [UUID: PropertyProxy] = [:]
    
    private init() {}
    
    func proxy(for id: UUID, initialOffset: CGFloat) -> PropertyProxy {
        if let existing = proxies[id] {
            return existing
        }
        let newProxy = PropertyProxy(id: id, initialOffset: initialOffset)
        proxies[id] = newProxy
        return newProxy
    }
    
    func remove(id: UUID) {
        print(">>>>> remove: \(id)")
        proxies.removeValue(forKey: id)
    }
} 