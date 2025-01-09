import SwiftUI
import CryptoKit

public class ImageCache {
    public static let shared = ImageCache()
    private let cache = NSCache<NSString, UIImage>()
    private let fileManager = FileManager.default
    
    private init() {}
    
    // MARK: - Public API
    
    /// Retrieves an image either from memory cache, disk cache, or downloads it.
    public func getImage(from urlString: String) async -> UIImage? {
        print("🔍 Attempting to load image from: \(urlString)")
        // 1) Check in-memory cache first
        if let cachedImage = cache.object(forKey: urlString as NSString) {
            return cachedImage
        }
        
        // 2) Check disk cache
        if let diskCachedImage = loadImageFromDisk(urlString: urlString) {
            // Put it into the in-memory cache
            cache.setObject(diskCachedImage, forKey: urlString as NSString)
            return diskCachedImage
        }
        
        // 3) If not found, download
        return await downloadAndCacheImage(from: urlString)
    }
    
    /// Stores an image manually (both in memory and on disk).
    public func storeImage(_ image: UIImage, forKey key: String) {
        // 1) Store in memory
        cache.setObject(image, forKey: key as NSString)
        // 2) Store on disk
        saveImageToDisk(image, urlString: key)
    }
    
    /// Removes an image from memory and disk cache.
    public func removeImage(for urlString: String) {
        // Remove from memory cache
        cache.removeObject(forKey: urlString as NSString)
        
        // Remove from disk cache
        guard let cacheDir = cacheDirectory else { return }
        let fileURL = cacheDir.appendingPathComponent(urlString.md5Hash)
        try? fileManager.removeItem(at: fileURL)
    }
    
    /// Retrieves a local image (from your iCloud vault, etc.), caches it, returns it.
    public func getLocalImage(named filename: String) async -> UIImage? {
        // 1) Check in-memory
        if let cachedImage = cache.object(forKey: filename as NSString) {
            return cachedImage
        }
        
        // 2) Check on disk
        if let diskCachedImage = loadImageFromDisk(urlString: filename) {
            cache.setObject(diskCachedImage, forKey: filename as NSString)
            return diskCachedImage
        }
        
        // 3) If not found locally, attempt reading from iCloud vault path
        guard let iconPath = ProjectFileManager.shared.getIconPath(filename: filename),
              let image = UIImage(contentsOfFile: iconPath.path)
        else {
            return nil
        }
        
        // Cache in memory + disk
        cache.setObject(image, forKey: filename as NSString)
        saveImageToDisk(image, urlString: filename)
        return image
    }
    
    /// Synchronously gets an image from cache (memory or disk)
    public func getImage(from key: String) -> UIImage? {
        // 1) Check in-memory cache first
        if let cachedImage = cache.object(forKey: key as NSString) {
            return cachedImage
        }
        
        // 2) Check disk cache
        if let diskCachedImage = loadImageFromDisk(urlString: key) {
            // Put it into the in-memory cache
            cache.setObject(diskCachedImage, forKey: key as NSString)
            return diskCachedImage
        }
        
        return nil
    }
    
    // MARK: - Internal/Private
    
    private var cacheDirectory: URL? {
        // Place images in a subfolder of the user’s Cache directory
        fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first?
            .appendingPathComponent("ImageCache")
    }
    
    /// Downloads & caches an image from a remote URL
    private func downloadAndCacheImage(from urlString: String) async -> UIImage? {
        guard let url = URL(string: urlString) else { return nil }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let image = UIImage(data: data) else { return nil }
            // Store in memory & on disk
            cache.setObject(image, forKey: urlString as NSString)
            saveImageToDisk(image, urlString: urlString)
            return image
        } catch {
            print("Error downloading image: \(error)")
            return nil
        }
    }
    
    /// Saves a PNG version of the image to our disk cache
    private func saveImageToDisk(_ image: UIImage, urlString: String) {
        guard let data = image.pngData(),
              let cacheDir = cacheDirectory else { return }
        
        do {
            // Create folder if missing
            if !fileManager.fileExists(atPath: cacheDir.path) {
                try fileManager.createDirectory(at: cacheDir, withIntermediateDirectories: true)
            }
            // Write the file
            let fileURL = cacheDir.appendingPathComponent(urlString.md5Hash)
            try data.write(to: fileURL)
        } catch {
            print("Error saving image to disk: \(error)")
        }
    }
    
    /// Loads an image from our disk cache (if present)
    private func loadImageFromDisk(urlString: String) -> UIImage? {
        guard let cacheDir = cacheDirectory else { return nil }
        let fileURL = cacheDir.appendingPathComponent(urlString.md5Hash)
        guard fileManager.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL),
              let image = UIImage(data: data)
        else {
            return nil
        }
        return image
    }
}

// MARK: - MD5 Hashing
extension String {
    var md5Hash: String {
        let digest = Insecure.MD5.hash(data: self.data(using: .utf8) ?? Data())
        return digest.map { String(format: "%02hhx", $0) }.joined()
    }
}
