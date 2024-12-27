import SwiftUI

public struct CachedAsyncImage: View {
    let source: ImageSource
    let width: CGFloat
    let height: CGFloat
    
    @State private var image: UIImage?
    
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
        .task {
            switch source {
            case .url(let urlString):
                image = await ImageCache.shared.getImage(from: urlString)
            case .local(let filename):
                image = await ImageCache.shared.getLocalImage(named: filename)
            }
        }
    }
} 