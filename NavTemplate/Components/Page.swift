// Page.swift

import SwiftUI

protocol Page: View {
    var navigationManager: NavigationManager? { get set }
    var widgets: [AnyWidget] { get }
    var viewModel: PageViewModel { get }
    
    @ViewBuilder func makeMainContent() -> AnyView
}

extension Page {
    var viewModel: PageViewModel { PageViewModel.shared }
    
    var body: some View {
        ZStack {
            makeMainContent()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            ForEach(widgets) { widget in
                widget
            }
        }
        .background(ColorUtilities.fromHex("#5f2215"))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .gesture(widgetGestures())
        .navigationBarBackButtonHidden(viewModel.isBackButtonHidden)
    }
    
    private func widgetGestures() -> AnyGesture<Void> {
        // Safely unwrap and handle gestures
        let validGestures = widgets.compactMap { $0.gestureWrapper }
        
        guard !validGestures.isEmpty else {
            return AnyGesture(DragGesture().map { _ in })
        }
        
        // Use first gesture as base and safely combine others
        return validGestures.dropFirst().reduce(validGestures[0]) { result, next in
            AnyGesture(
                result.simultaneously(with: next)
                    .map { _ in }
            )
        }
    }
}

