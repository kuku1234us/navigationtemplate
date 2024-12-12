// NavigationState.swift

import SwiftUI

class NavigationState: ObservableObject {
    @Published var isBackButtonHidden: Bool = false
    private var activeWidgetId: UUID?
    
    // Add bottom menu height constant
    static let bottomMenuHeight: CGFloat = 70
    
    static let shared = NavigationState()
    private init() {}
    
    // Active widget ID accessors
    func getActiveWidgetId() -> UUID? {
        return activeWidgetId
    }
    
    func setActiveWidgetId(_ id: UUID?) {
        activeWidgetId = id
    }
    
    func dismissSheet(proxy: PropertyProxy, direction: DragGestureHandler.DragDirection) {
        withAnimation(.easeOut(duration: 0.2)) {
            proxy.offset = direction == .leftToRight ? 
                -SheetConstants.width : SheetConstants.width
        }
        
        // Clear active widget when dismissing
        setActiveWidgetId(nil)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            proxy.isActive = false
            proxy.isExpanded = false
            
            // Force UI update by dispatching to main queue
            // Force UI update by dispatching to main queue
            DispatchQueue.main.async {
                self.isBackButtonHidden = false
                self.objectWillChange.send()
            }
        }
    }
    
    func expandSheet(proxy: PropertyProxy) {        
        withAnimation(.easeOut(duration: 0.2)) {
            proxy.offset = 0
        }
    }
} 
