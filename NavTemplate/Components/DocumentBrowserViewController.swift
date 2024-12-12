import UIKit
import SwiftUI

class DocumentBrowserViewController: UIDocumentBrowserViewController, UIDocumentBrowserViewControllerDelegate {
    
    var onFileSelected: ((URL) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        allowsDocumentCreation = false
        allowsPickingMultipleItems = false
        
        // Show the Files interface including iCloud Drive
        browserUserInterfaceStyle = .dark
    }
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, didPickDocumentsAt documentURLs: [URL]) {
        guard let url = documentURLs.first else { return }
        
        // Start accessing the security-scoped resource
        guard url.startAccessingSecurityScopedResource() else {
            print("Failed to get security scope access")
            return
        }
        
        defer {
            url.stopAccessingSecurityScopedResource()
        }
        
        // Call the callback with the URL
        onFileSelected?(url)
        
        do {
            // For text files
            if url.pathExtension == "txt" || url.pathExtension == "md" {
                let contents = try String(contentsOf: url, encoding: .utf8)
                print("File contents: \(contents)")
            }
            
            // For folders
            if (try url.resourceValues(forKeys: [.isDirectoryKey])).isDirectory == true {
                let contents = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
                contents.forEach { itemURL in
                    print("Folder item: \(itemURL.lastPathComponent)")
                }
            }
            
        } catch {
            print("Error reading file: \(error)")
        }
    }
} 