// HomePage.swift

import SwiftUI

struct HomePage: Page {
    var id: UUID = UUID()
    var navigationManager: NavigationManager?
    var widgets: [any Widget] = []
    var gestures: [AnyGesture<()>] = []

    init(navigationManager: NavigationManager?) {
        self.navigationManager = navigationManager
    }

    func makeMainContent() -> AnyView {
        AnyView(
            VStack {
                Text("Home Page")
                    .font(.largeTitle)
                Button("Go to Book Page") {
                    let bookPage = BookPage(title: "Sample Book", author: "John Doe", navigationManager: navigationManager)
                    navigationManager?.navigate(to: AnyPage(bookPage))
                }
                Button("Go to Daily Page") {
                    let dailyPage = DailyPage(date: Date(), navigationManager: navigationManager)
                    navigationManager?.navigate(to: AnyPage(dailyPage))
                }
            }
        )
    }
}
