import Foundation
import SwiftUI

class ObsidianVaultAccess: ObservableObject {
    static let shared = ObsidianVaultAccess()
    @Published var isVaultAccessible = false
    var vaultURL: URL?
    
    private init() {
        restoreVaultAccess()
    }
    
    var vaultName: String? {
        vaultURL?.lastPathComponent
    }
    
    func saveVaultBookmark(url: URL) {
        print("Attempting to save bookmark for: \(url.path)")
        
        // First verify we can access the URL
        guard url.startAccessingSecurityScopedResource() else {
            print("Failed to get initial security scope access")
            return
        }
        
        // Verify it's a directory and exists
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory),
              isDirectory.boolValue else {
            print("URL is not a directory or doesn't exist")
            url.stopAccessingSecurityScopedResource()
            return
        }
        
        do {
            // Create bookmark while we have access
            let bookmark = try url.bookmarkData(
                options: [.minimalBookmark],
                includingResourceValuesForKeys: [.isDirectoryKey],
                relativeTo: nil
            )
            
            UserDefaults.standard.set(bookmark, forKey: "obsidianVaultBookmark")
            vaultURL = url
            isVaultAccessible = true
            print("Successfully saved bookmark for: \(url.path)")
            
            // Test immediate access
            if let files = listMarkdownFiles() {
                print("Found \(files.count) markdown files")
            }
        } catch {
            print("Failed to save bookmark: \(error)")
        }
        
        url.stopAccessingSecurityScopedResource()
    }
    
    func restoreVaultAccess() {
        guard let bookmark = UserDefaults.standard.data(forKey: "obsidianVaultBookmark") else {
            return
        }
        
        do {
            var isStale = false
            let url = try URL(
                resolvingBookmarkData: bookmark,
                options: [],
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
            
            if url.startAccessingSecurityScopedResource() {
                vaultURL = url
                isVaultAccessible = true
                print("Restored access to: \(url.path)")
            }
        } catch {
            print("Failed to restore access: \(error)")
        }
    }
    
    // Get list of markdown files in vault
    func listMarkdownFiles() -> [URL]? {
        guard let url = vaultURL,
              url.startAccessingSecurityScopedResource() else { return nil }
        defer { url.stopAccessingSecurityScopedResource() }
        
        do {
            let files = try FileManager.default.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: .skipsHiddenFiles
            )
            
            return files.filter { $0.pathExtension == "md" }
        } catch {
            print("Error listing files: \(error)")
            return nil
        }
    }
    
    // Read contents of a markdown file
    func readMarkdownFile(at url: URL) -> String? {
        guard url.startAccessingSecurityScopedResource() else { return nil }
        defer { url.stopAccessingSecurityScopedResource() }
        
        do {
            return try String(contentsOf: url, encoding: .utf8)
        } catch {
            print("Error reading file: \(error)")
            return nil
        }
    }
    
    struct VaultItem: Identifiable, Hashable {
        let url: URL
        let isDirectory: Bool
        let itemCount: Int?  // For directories
        
        var id: String { url.absoluteString }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(url)
        }
        
        static func == (lhs: VaultItem, rhs: VaultItem) -> Bool {
            lhs.url == rhs.url
        }
    }
    
    // Get list of all items in vault or subfolder
    func listVaultItems(in directory: URL? = nil) -> [VaultItem]? {
        let targetURL = directory ?? vaultURL
        guard let url = targetURL,
              url.startAccessingSecurityScopedResource() else { return nil }
        defer { url.stopAccessingSecurityScopedResource() }
        
        do {
            let files = try FileManager.default.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: .skipsHiddenFiles
            )
            
            return try files.map { url -> VaultItem in
                let resourceValues = try url.resourceValues(forKeys: [.isDirectoryKey])
                let isDirectory = resourceValues.isDirectory ?? false
                
                if isDirectory {
                    // Count items in directory
                    let contents = try FileManager.default.contentsOfDirectory(
                        at: url,
                        includingPropertiesForKeys: nil,
                        options: .skipsHiddenFiles
                    )
                    return VaultItem(url: url, isDirectory: true, itemCount: contents.count)
                } else {
                    return VaultItem(url: url, isDirectory: false, itemCount: nil)
                }
            }.sorted { $0.isDirectory && !$1.isDirectory || $0.url.lastPathComponent < $1.url.lastPathComponent }
        } catch {
            print("Error listing items: \(error)")
            return nil
        }
    }
    
    func createMarkdownFile(named filename: String, content: String, in directory: URL? = nil) -> Bool {
        let targetURL = directory ?? vaultURL
        print(">>>>> Creating file in: \(targetURL?.path ?? "nil")")
        guard let url = targetURL,
              url.startAccessingSecurityScopedResource() else { return false }
        defer { url.stopAccessingSecurityScopedResource() }
        
        let fileURL = url.appendingPathComponent(filename)
        
        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            print("Successfully created file: \(fileURL.path)")
            return true
        } catch {
            print("Error creating file: \(error)")
            return false
        }
    }
} 