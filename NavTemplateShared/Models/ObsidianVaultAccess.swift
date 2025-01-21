import Foundation

public class ObsidianVaultAccess {
    public static let shared = ObsidianVaultAccess()
    
    // App Group identifier
    private let groupID = "group.us.kothreat.NavTemplate"
    private let bookmarkKey = "ObsidianVaultBookmark"
    
    private var groupDefaults: UserDefaults? {
        UserDefaults(suiteName: groupID)
    }
    
    private init() {
        // Initialize with any stored bookmark
        if let url = vaultURL {
            // print("ObsidianVaultAccess: Found existing vault bookmark at \(url.path)")
        }
    }
    
    public var vaultURL: URL? {
        // Try to get bookmark data from shared defaults
        guard let bookmarkData = groupDefaults?.data(forKey: bookmarkKey) else {
            print("ObsidianVaultAccess: No bookmark data found in group defaults")
            return nil
        }
        
        var isStale = false
        do {
            let url = try URL(
                resolvingBookmarkData: bookmarkData,
                options: [],
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
            
            if isStale {
                try saveBookmark(for: url)
                print("ObsidianVaultAccess: Updated stale bookmark")
            }
            
            return url
        } catch {
            print("ObsidianVaultAccess: Error resolving bookmark: \(error)")
            return nil
        }
    }
    
    public func saveVaultURL(_ url: URL) {
        do {
            try saveBookmark(for: url)
            print("ObsidianVaultAccess: Successfully saved vault bookmark")
        } catch {
            print("ObsidianVaultAccess: Error saving vault bookmark: \(error)")
        }
    }
    
    // New method that maintains consistency with existing code
    public func saveVaultBookmark(_ bookmarkData: Data) {
        groupDefaults?.set(bookmarkData, forKey: bookmarkKey)
        print("ObsidianVaultAccess: Directly saved vault bookmark data")
    }
    
    private func saveBookmark(for url: URL) throws {
        let bookmarkData = try url.bookmarkData(
            options: .minimalBookmark,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
        groupDefaults?.set(bookmarkData, forKey: bookmarkKey)
    }
    
    // Add method to clear vault access
    public func clearVaultAccess() {
        groupDefaults?.removeObject(forKey: bookmarkKey)
        print("ObsidianVaultAccess: Cleared vault bookmark")
    }
} 