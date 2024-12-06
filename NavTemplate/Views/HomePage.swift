// HomePage.swift

import SwiftUI

struct HomePage: Page {
    @EnvironmentObject var navigationState: NavigationState
    var navigationManager: NavigationManager?

    var widgets: [AnyWidget] {
        return []
    }

    init(navigationManager: NavigationManager?) {
        self.navigationManager = navigationManager
    }

    func makeMainContent() -> AnyView {
        AnyView(
            VStack {
                Text("Home Page")
                    .font(.largeTitle)
                Button("Go to Book Page") {
                    let bookPage = BookPage(
                        navigationManager: navigationManager,
                        title: "Sample Book",
                        author: "John Doe"
                    )
                    navigationManager?.navigate(to: AnyPage(bookPage))
                }
                Button("Go to Daily Page") {
                    let dailyPage = DailyPage(
                        date: Date(),
                        navigationManager: navigationManager
                    )
                    navigationManager?.navigate(to: AnyPage(dailyPage))
                }
            }
            .padding()
        )
    }
}
