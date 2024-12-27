// BookPage.swift

import SwiftUI
import NavTemplateShared

struct BookPage: Page {
    var navigationManager: NavigationManager?
    let title: String
    let author: String
    
    // Create stable ID
    private let rightSheetId = UUID()
    
    var widgets: [AnyWidget] {
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

        return [AnyWidget(rightWidget)]
    }
    
    let iconUrl = "https://www.flaticon.com/download/icon/3281289?icon_id=3281289&author=266&team=266&keyword=Suitcase&pack=packs%2Fstrategy-and-management-24&style=8&format=png&color=%23000000&colored=2&size=128"
    
    func makeMainContent() -> AnyView {
        AnyView(
            VStack(spacing: 20) {
                Text("Book Page")
                    .font(.largeTitle)
                
                Text("Title: \(title)")
                Text("Author: \(author)")
                
                Button("Go Back") {
                    navigationManager?.navigateBack()
                }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onDisappear {
                PropertyProxyFactory.shared.remove(id: rightSheetId)
                NavigationState.shared.setActiveWidgetId(nil)
            }
        )
    }
}

// Move RightSideSheetContent outside BookPage
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
