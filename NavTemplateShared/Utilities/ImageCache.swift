import SwiftUI
import CryptoKit

public class ImageCache {
    public static let shared = ImageCache()
    private let cache = NSCache<NSString, UIImage>()
    private let fileManager = FileManager.default
    
    private init() {}
    
    // Helper to generate complete cache key
    private func makeCacheKey(folder: String, filename: String) -> String {
        "image_\(folder)_\(filename)"
    }
    
    // MARK: - Public API
    
    /// Retrieves an image either from memory cache, UserDefaults, or downloads it.
    public func getImageFromWeb(folder: String, from urlString: String) async -> UIImage? {
        print("🔍 Attempting to load image from: \(urlString)")
        let cacheKey = makeCacheKey(folder: folder, filename: urlString)
        
        // 1) Check in-memory cache first
        if let cachedImage = cache.object(forKey: cacheKey as NSString) {
            return cachedImage
        }
        
        // 2) Check UserDefaults
        if let defaultsCachedImage = loadImageFromDefaults(folder: folder, key: urlString) {
            cache.setObject(defaultsCachedImage, forKey: cacheKey as NSString)
            return defaultsCachedImage
        }
        
        // 3) If not found, download
        return await downloadAndCacheImage(folder: folder, from: urlString)
    }
    
    /// Removes an image from memory and UserDefaults.
    public func removeImage(folder: String, filename: String) {
        let cacheKey = makeCacheKey(folder: folder, filename: filename)
        cache.removeObject(forKey: cacheKey as NSString)
        
        let defaults = UserDefaults(suiteName: "group.us.kothreat.NavTemplate")
        defaults?.removeObject(forKey: cacheKey)
    }
    
    /// Retrieves a local image (from your iCloud vault, etc.), caches it, returns it.
    public func getLocalImage(folder: String, filename: String) async -> UIImage? {
        let cacheKey = makeCacheKey(folder: folder, filename: filename)
        
        // 1) Check in-memory
        if let cachedImage = cache.object(forKey: cacheKey as NSString) {
            return cachedImage
        }
        
        // 2) Check UserDefaults
        if let defaultsCachedImage = loadImageFromDefaults(folder: folder, key: filename) {
            cache.setObject(defaultsCachedImage, forKey: cacheKey as NSString)
            return defaultsCachedImage
        }
        
        // 3) If not found locally, attempt reading from iCloud vault path
        guard let iconPath = ProjectFileManager.shared.getIconPath(filename: filename),
              let image = UIImage(contentsOfFile: iconPath.path)
        else {
            return nil
        }
        
        // Cache in memory + UserDefaults
        cache.setObject(image, forKey: cacheKey as NSString)
        saveImageToDefaults(image, folder: folder, key: filename)
        return image
    }
    
    /// Retrieves an image from memory cache or UserDefaults (used by widget)
    public func getImageFromDefaults(folder: String, key: String) -> UIImage? {
        let cacheKey = makeCacheKey(folder: folder, filename: key)
        
        // 1) Check in-memory cache first
        if let cachedImage = cache.object(forKey: cacheKey as NSString) {
            return cachedImage
        }
        
        // 2) Check UserDefaults
        if let defaultsImage = loadImageFromDefaults(folder: folder, key: key) {
            // Store in memory cache for future use
            cache.setObject(defaultsImage, forKey: cacheKey as NSString)
            return defaultsImage
        }
        
        // 3) Not found in either location
        return nil
    }
    
    /// Removes images from a specific folder in UserDefaults that are not in the provided set of filenames
    public func removeUnusedImages(folder: String, currentlyUsedFilenames: Set<String>) {
        let defaults = UserDefaults(suiteName: "group.us.kothreat.NavTemplate")
        let folderPrefix = "image_\(folder)_"
        
        // Get all keys from UserDefaults that start with the folder prefix
        if let keys = defaults?.dictionaryRepresentation().keys.filter({ $0.hasPrefix(folderPrefix) }) {
            // For each key, extract the filename and check if it's still in use
            for key in keys {
                let filename = String(key.dropFirst(folderPrefix.count))
                if !currentlyUsedFilenames.contains(filename) {
                    Logger.shared.info("[I002] Removing unused image from \(folder): \(filename)")
                    defaults?.removeObject(forKey: key)
                    cache.removeObject(forKey: filename as NSString)
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func downloadAndCacheImage(folder: String, from urlString: String) async -> UIImage? {
        guard let url = URL(string: urlString) else { return nil }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let image = UIImage(data: data) else { return nil }
            
            // Store in memory & UserDefaults
            let cacheKey = makeCacheKey(folder: folder, filename: urlString)
            cache.setObject(image, forKey: cacheKey as NSString)
            saveImageToDefaults(image, folder: folder, key: urlString)
            return image
        } catch {
            print("Error downloading image: \(error)")
            return nil
        }
    }
    
    private func saveImageToDefaults(_ image: UIImage, folder: String, key: String) {
        guard let imageData = image.pngData() else { return }
        let defaults = UserDefaults(suiteName: "group.us.kothreat.NavTemplate")
        let cacheKey = makeCacheKey(folder: folder, filename: key)
        defaults?.set(imageData, forKey: cacheKey)
    }
    
    private func loadImageFromDefaults(folder: String, key: String) -> UIImage? {
        let defaults = UserDefaults(suiteName: "group.us.kothreat.NavTemplate")
        let cacheKey = makeCacheKey(folder: folder, filename: key)
        guard let imageData = defaults?.data(forKey: cacheKey) else { return nil }
        return UIImage(data: imageData)
    }
}

// MARK: - MD5 Hashing
extension String {
    var md5Hash: String {
        let digest = Insecure.MD5.hash(data: self.data(using: .utf8) ?? Data())
        return digest.map { String(format: "%02hhx", $0) }.joined()
    }
}
