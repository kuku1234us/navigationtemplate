import SwiftUI

/// A view that asynchronously loads and displays an image from either a local file or URL.
/// This implementation handles automatic reloading when the image source changes.
public struct CachedAsyncImage: View {
    let source: ImageSource
    let width: CGFloat
    let height: CGFloat
    
    @State private var image: UIImage?
    
    /// Defines the possible sources for the image
    public enum ImageSource {
        case url(String)
        case local(String)
    }
    
    public init(source: ImageSource, width: CGFloat, height: CGFloat) {
        self.source = source
        self.width = width
        self.height = height
    }
    
    public var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: width, height: height)
            } else {
                ProgressView()
                    .frame(width: width, height: height)
            }
        }
        // The task(id:) modifier is key to handling source changes.
        // When the sourceId changes:
        // 1. The existing task is cancelled
        // 2. A new task is started with the new source
        // 3. The image is reloaded from the new source
        //
        // This solves the issue where the view might not update when its source
        // changes (e.g., when a project's icon is changed or when an event is
        // moved to a different project).
        .task(id: sourceId) {
            switch source {
            case .url(let urlString):
                image = await ImageCache.shared.getImageFromWeb(folder: "web", from: urlString)
            case .local(let filename):
                image = await ImageCache.shared.getLocalImage(folder: "projecticon", filename: filename)
            }
        }
    }
    
    /// Creates a unique identifier for the current image source.
    /// This ID changes whenever the source changes, triggering a reload of the image.
    ///
    /// Without this mechanism, the view might continue showing a cached image
    /// even after its source has changed, leading to stale or incorrect images
    /// being displayed.
    private var sourceId: String {
        switch source {
        case .url(let urlString):
            return "url-\(urlString)"
        case .local(let filename):
            return "local-\(filename)"
        }
    }
} 