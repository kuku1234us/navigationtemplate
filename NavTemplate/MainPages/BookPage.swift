// BookPage.swift

import SwiftUI

struct BookPage: Page {
    var navigationManager: NavigationManager?

    @State private var debugText: String = "No gesture detected"
    @State private var translation: CGPoint = .zero

    let title: String
    let author: String

    // Create stable IDs
    private let leftSheetId = UUID()
    private let rightSheetId = UUID()

    var widgets: [AnyWidget] {
        // Left sheet setup
        let leftSideSheet = SideSheet(
            id: leftSheetId,
            content: {
                LeftSideSheetContent(title: title, author: author)
            },
            direction: .leftToRight
        )

        let leftGestureHandler = DragGestureHandler(
            proxy: leftSideSheet.proxy,
            direction: .leftToRight
        )

        let leftWidget = WidgetWithGesture(
            widget: leftSideSheet,
            gesture: leftGestureHandler
        )

        // Right sheet setup
        let rightSideSheet = SideSheet(
            id: rightSheetId,
            content: {
                RightSideSheetContent()
            },
            direction: .rightToLeft
        )

        let rightGestureHandler = DragGestureHandler(
            proxy: rightSideSheet.proxy,
            direction: .rightToLeft
        )

        let rightWidget = WidgetWithGesture(
            widget: rightSideSheet,
            gesture: rightGestureHandler
        )

        return [AnyWidget(leftWidget), AnyWidget(rightWidget)]
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
            .onDisappear {
                PropertyProxyFactory.shared.remove(id: leftSheetId)
                PropertyProxyFactory.shared.remove(id: rightSheetId)
                NavigationState.shared.setActiveWidgetId(nil)
            }
        )
    }

    // Move LeftSideSheetContent inside BookPage
    private struct LeftSideSheetContent: View {
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
        }
    }

    private struct RightSideSheetContent: View {
        var body: some View {
            VStack(spacing: 0) {
                Text("Chapters")
                    .font(.headline)
                    .padding()
                
                List(1...10, id: \.self) { chapter in
                    Text("Chapter \(chapter)")
                }
                .listStyle(.plain)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
