// Page.swift

import SwiftUI

protocol Page: View {
    var id: UUID { get }
    var widgets: [any Widget] { get set }
    var navigationManager: NavigationManager? { get set }

    @ViewBuilder func makeMainContent() -> AnyView
}

extension Page {
    var id: UUID { UUID() }

    var hasActiveWidget: Bool {
        widgets.contains { $0.isActive }
    }

    var body: some View {
        ZStack {
            makeMainContent()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .edgesIgnoringSafeArea(.all)
                .gesture(combinedGesture())
            
            if hasActiveWidget {
                Color.black.opacity(0.01)
                    .frame(height: 44)
                    .frame(maxWidth: .infinity)
                    .edgesIgnoringSafeArea(.top)
                    .zIndex(500)
            }
            
            ForEach(widgets.indices, id: \.self) { index in
                if let widget = widgets[index] as? BaseWidget {
                    WidgetView(widget: widget)
                        .zIndex(999)
                }
            }
        }
        .navigationBarHidden(hasActiveWidget)
    }

    private func combinedGesture() -> AnyGesture<()> {
        func debugGestures() {
            print("Processing gestures:")
            widgets.forEach { widget in
                print("- Widget type: \(type(of: widget)), has gesture: \(widget.gesture != nil)")
            }
        }
        
        debugGestures()
        
        let gestures = widgets.compactMap { $0.gesture }
        print("Combined gestures count: \(gestures.count)")
        
        guard !gestures.isEmpty else {
            print("No gestures found")
            return AnyGesture(DragGesture(minimumDistance: 0).map { _ in () })
        }
        
        guard gestures.count > 1 else {
            print("Single gesture found")
            return gestures[0]
        }
        
        print("Multiple gestures found: \(gestures.count)")
        var combinedGesture = gestures[0]
        for gesture in gestures.dropFirst() {
            combinedGesture = AnyGesture(
                combinedGesture
                    .simultaneously(with: gesture)
                    .map { _ in () }
            )
        }
        
        return combinedGesture
    }
}

