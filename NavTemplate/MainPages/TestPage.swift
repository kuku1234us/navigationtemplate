import SwiftUI
import NavTemplateShared

struct TestPage: Page {
    var navigationManager: NavigationManager?
    var widgets: [AnyWidget] { [] }

    // yellow
    @State private var originalRect: CGRect = CGRect(x: 0, y: 0, width: 130, height: 80)
    // red
    @State private var rect1: CGRect = CGRect(x: 50, y: 100, width: 150, height: 90)
    // blue
    @State private var rect2: CGRect = CGRect(x: 100, y: 200, width: 100, height: 150)

    func makeMainContent() -> AnyView {
        AnyView(
            ZStack(alignment: .topLeading) {
                // Add a background to visualize the container
                Color.gray.opacity(0.2)
                
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: originalRect.width, height: originalRect.height)
                    .border(.yellow)
                    .offset(
                        x: originalRect.minX,
                        y: originalRect.minY
                    )

                Rectangle()
                    .fill(Color.clear)
                    .frame(width: rect1.width, height: rect1.height)
                    .border(.red)
                    .offset(
                        x: rect1.minX,
                        y: rect1.minY
                    )
                
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: rect2.width, height: rect2.height)
                    .border(.blue)
                    .offset(
                        x: rect2.minX,
                        y: rect2.minY
                    )
            }

        )
    }
}

