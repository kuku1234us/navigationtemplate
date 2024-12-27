import SwiftUI
import CryptoKit

public class ImageCache {
    public static let shared = ImageCache()
    private let cache = NSCache<NSString, UIImage>()
    private let fileManager = FileManager.default
    
    private init() {}
    
    private var cacheDirectory: URL? {
        fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first?
            .appendingPathComponent("ImageCache")
    }
    
    public func getImage(from urlString: String) async -> UIImage? {
        print("🔍 Attempting to load image from: \(urlString)")
        // Check memory cache first
        if let cachedImage = cache.object(forKey: urlString as NSString) {
            return cachedImage
        }
        
        // Check disk cache
        if let diskCachedImage = loadImageFromDisk(urlString: urlString) {
            // Store in memory cache
            cache.setObject(diskCachedImage, forKey: urlString as NSString)
            return diskCachedImage
        }
        
        // Download if not cached
        return await downloadAndCacheImage(from: urlString)
    }
    
    private func downloadAndCacheImage(from urlString: String) async -> UIImage? {
        guard let url = URL(string: urlString) else { return nil }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let image = UIImage(data: data) else { return nil }
            
            // Cache in memory
            cache.setObject(image, forKey: urlString as NSString)
            
            // Cache to disk
            saveImageToDisk(image, urlString: urlString)
            
            return image
        } catch {
            print("Error downloading image: \(error)")
            return nil
        }
    }
    
    private func saveImageToDisk(_ image: UIImage, urlString: String) {
        guard let data = image.pngData(),
              let cacheDir = cacheDirectory else { return }
        
        do {
            // Create cache directory if it doesn't exist
            if !fileManager.fileExists(atPath: cacheDir.path) {
                try fileManager.createDirectory(at: cacheDir, withIntermediateDirectories: true)
            }
            
            // Save image
            let fileURL = cacheDir.appendingPathComponent(urlString.md5Hash)
            try data.write(to: fileURL)
        } catch {
            print("Error saving image to disk: \(error)")
        }
    }
    
    private func loadImageFromDisk(urlString: String) -> UIImage? {
        guard let cacheDir = cacheDirectory else { return nil }
        let fileURL = cacheDir.appendingPathComponent(urlString.md5Hash)
        
        guard fileManager.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL),
              let image = UIImage(data: data) else {
            return nil
        }
        
        return image
    }
    
    public func removeImage(for urlString: String) {
        // Remove from memory cache
        cache.removeObject(forKey: urlString as NSString)
        
        // Remove from disk cache
        guard let cacheDir = cacheDirectory else { return }
        let fileURL = cacheDir.appendingPathComponent(urlString.md5Hash)
        
        try? FileManager.default.removeItem(at: fileURL)
    }
    
    public func getLocalImage(named filename: String) async -> UIImage? {
        // Check memory cache first
        if let cachedImage = cache.object(forKey: filename as NSString) {
            return cachedImage
        }
        
        // Check disk cache
        if let diskCachedImage = loadImageFromDisk(urlString: filename) {
            // Store in memory cache
            cache.setObject(diskCachedImage, forKey: filename as NSString)
            return diskCachedImage
        }
        
        // Load from iCloud vault and cache
        guard let iconPath = ProjectFileManager.shared.getIconPath(filename: filename),
              let image = UIImage(contentsOfFile: iconPath.path) else {
            return nil
        }
        
        // Cache in memory
        cache.setObject(image, forKey: filename as NSString)
        
        // Cache to disk
        saveImageToDisk(image, urlString: filename)
        
        return image
    }
}

// Helper extension for MD5 hashing
extension String {
    var md5Hash: String {
        let digest = Insecure.MD5.hash(data: self.data(using: .utf8) ?? Data())
        return digest.map { String(format: "%02hhx", $0) }.joined()
    }
} 