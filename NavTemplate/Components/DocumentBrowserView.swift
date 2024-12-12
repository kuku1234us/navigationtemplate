import SwiftUI
import UniformTypeIdentifiers

struct DocumentBrowserView: UIViewControllerRepresentable {
    var onFileSelected: (URL) -> Void
    
    func makeUIViewController(context: Context) -> DocumentBrowserViewController {
        // Create array of supported content types
        let contentTypes = [
            UTType.folder,
            UTType.text,
            UTType.plainText,
            UTType(filenameExtension: "md")!,  // For markdown files
            UTType(filenameExtension: "markdown")!
        ].compactMap { $0 }  // Remove any nil values
        
        let controller = DocumentBrowserViewController(forOpening: contentTypes)
        controller.onFileSelected = { url in
            onFileSelected(url)
        }
        return controller
    }
    
    func updateUIViewController(_ uiViewController: DocumentBrowserViewController, context: Context) {
        // Updates if needed
    }
} 