import SwiftUI

struct ViewToImage<Content: View>: View {
    let content: Content
    @State private var renderedImage: UIImage? = nil

    init(_ content: Content) {
        self.content = content
    }

    var body: some View {
        Group {
            if let renderedImage = renderedImage {
                Image(uiImage: renderedImage)
                    .resizable()
                    .scaledToFit()
                    .fixedSize()
            } else {
                Text("Rendering image...")
                    .foregroundColor(.gray)
                    .onAppear {
                        renderToImage()
                    }
            }
        }
    }

    private func renderToImage() {
        let renderer = ImageRenderer(content: content)
        // Ensure the background is transparent
        renderer.isOpaque = false
        
        // Set the scale to match device's screen scale
        renderer.scale = UIScreen.main.scale
        
        if let image = renderer.uiImage {
            DispatchQueue.main.async {
                self.renderedImage = image
            }
        }
    }
}
