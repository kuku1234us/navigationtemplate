// NavigationState.swift

import SwiftUI

class NavigationState: ObservableObject {
    @Published var isBackButtonHidden: Bool = false
    
    static let shared = NavigationState()
    private init() {}
    
    func dismissSheet(isActive: Binding<Bool>, 
                     offset: Binding<CGFloat>,
                     isExpanded: Binding<Bool>? = nil,
                     directionChecked: Binding<Bool>? = nil,
                     isDragging: Binding<Bool>? = nil) {
        
        withAnimation(.easeOut(duration: 0.3)) {
            offset.wrappedValue = 0
        }
        
        // Reset drag-related states if provided
        isDragging?.wrappedValue = false
        directionChecked?.wrappedValue = false
        
        // Wait for animation and view cleanup to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isActive.wrappedValue = false
            isExpanded?.wrappedValue = false
            
            // Force UI update by dispatching to main queue
            DispatchQueue.main.async {
                self.isBackButtonHidden = false
                self.objectWillChange.send()  // Explicitly notify observers
            }
        }
    }
    
    func expandSheet(offset: Binding<CGFloat>) {
        withAnimation(.easeOut(duration: 0.3)) {
            offset.wrappedValue = SheetConstants.width
        }
    }
} 