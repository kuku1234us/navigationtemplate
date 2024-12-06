// BookPage.swift

import SwiftUI

struct BookPage: Page {
    var navigationManager: NavigationManager?

    @State private var isSideSheetActive: Bool = false
    @State private var sideSheetOffset: CGFloat = 0
    @State private var isDragging: Bool = false
    @State private var debugText: String = "No gesture detected"
    @State private var translation: CGPoint = .zero
    @State private var isExpanded: Bool = false
    @State private var directionChecked: Bool = false

    let title: String
    let author: String

    var widgets: [AnyWidget] {
        let sideSheet = SideSheet(
            content: {
                SideSheetContent(title: title, author: author)
            },
            isActive: $isSideSheetActive,
            offset: $sideSheetOffset,
            isDragging: $isDragging,
            isExpanded: $isExpanded,
            directionChecked: $directionChecked
        )

        let gestureHandler = DragGestureHandler(
            offset: $sideSheetOffset,
            isActive: $isSideSheetActive,
            debugText: $debugText,
            translation: $translation,
            isDragging: $isDragging,
            isExpanded: $isExpanded,
            direction: .leftToRight
        )

        let sideSheetWithGesture = WidgetWithGesture(
            widget: sideSheet,
            gesture: gestureHandler
        )

        return [AnyWidget(sideSheetWithGesture)]
    }

    func makeMainContent() -> AnyView {
        AnyView(
            VStack(spacing: 20) {
                Text("Book Page")
                    .font(.largeTitle)
                Text("Title: \(title)")
                Text("Author: \(author)")

                // Debug information
                VStack(alignment: .leading, spacing: 10) {
                    Text("Debug Info:")
                        .font(.headline)
                    Text(debugText)
                        .font(.system(.body, design: .monospaced))
                    Text("Translation: (\(translation.x.rounded()), \(translation.y.rounded()))")
                        .font(.system(.body, design: .monospaced))
                }
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)

                Button("Go Back") {
                    navigationManager?.navigateBack()
                }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        )
    }
}


struct SideSheetContent: View {
    let title: String
    let author: String

    var body: some View {
        VStack {
            Text("Book Details")
                .font(.largeTitle)
            Text("Title: \(title)")
            Text("Author: \(author)")
            Button("Close") {
                // Logic to close the side sheet
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ColorUtilities.fromHex("#151f5f"))
        .ignoresSafeArea()
    }
}
