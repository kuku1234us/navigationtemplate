import SwiftUI
import NavTemplateShared

struct TestPage: Page {
    var navigationManager: NavigationManager?
    
    var widgets: [AnyWidget] {
        return []
    }
    
    func makeMainContent() -> AnyView {
        AnyView(
            ZStack {
                // Background
                Image("batmanDim")
                    .resizable()
                    .ignoresSafeArea()
                    .overlay(.black.opacity(0.5))
          }
        )
    }
} 