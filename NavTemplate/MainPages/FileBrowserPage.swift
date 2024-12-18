import SwiftUI

struct FileBrowserPage: Page {
    @State private var selectedFileContents: String?
    
    var navigationManager: NavigationManager?
    var widgets: [AnyWidget] { [] }  // No widgets needed
    
    init(navigationManager: NavigationManager?) {
        self.navigationManager = navigationManager
    }
    
    func makeMainContent() -> AnyView {
        AnyView(
            VStack {
                DocumentBrowserView { url in
                    // Handle selected file
                    if let contents = try? String(contentsOf: url, encoding: .utf8) {
                        selectedFileContents = contents
                    }
                }
                
                if let contents = selectedFileContents {
                    ScrollView {
                        Text(contents)
                            .padding()
                    }
                }
            }
        )
    }
} 