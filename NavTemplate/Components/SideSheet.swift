// SideSheet.swift

import SwiftUI

class SideSheet<Content: View>: BaseWidget {
    let content: Content
    let gestureHandler: DragGestureHandler
    
    // Standard colors and dimensions
    private let backgroundColor = Color(uiColor: .systemGray6)
    private let overlayColor = Color.black.opacity(0.5)
    private let sheetWidth: CGFloat = UIScreen.main.bounds.width * 0.85
    
    init(@ViewBuilder content: () -> Content) {
        // First initialize stored properties
        self.content = content()
        
        // Create a temporary self reference for the gesture handler
        let widget = BaseWidget()
        self.gestureHandler = DragGestureHandler(
            widget: widget,
            direction: .leftToRight
        )
        
        // Call super.init()
        super.init()
        
        // Update the gesture handler with the correct widget reference
        self.gestureHandler.updateWidget(self)
    }
    
    override var gesture: AnyGesture<()>? {
        gestureHandler.makeGesture()
    }
    
    override func setActive(_ active: Bool) {
        print("SideSheet setActive called with: \(active)")
        super.setActive(active)
        print("SideSheet isActive is now: \(isActive)")
    }
    
    override var view: AnyView {
        let isActiveValue = isActive
        
        return AnyView(
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    if isActiveValue {
                        // Full screen overlay
                        self.overlayColor
                            .ignoresSafeArea()
                            .onTapGesture {
                                self.setActive(false)
                            }
                            .zIndex(1)
                        
                        // Side sheet content
                        VStack(spacing: 0) {
                            self.content
                                .frame(width: self.sheetWidth)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                        .background(
                            self.backgroundColor
                                .ignoresSafeArea()
                        )
                        .frame(width: self.sheetWidth)
                        .ignoresSafeArea()
                        .transition(.move(edge: .leading))
                        .zIndex(2)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .animation(.easeInOut, value: isActiveValue)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea()
        )
    }
}
