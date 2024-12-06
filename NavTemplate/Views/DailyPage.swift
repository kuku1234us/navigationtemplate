// DailyPage.swift

import SwiftUI

struct DailyPage: Page {
    @EnvironmentObject var navigationState: NavigationState
    var navigationManager: NavigationManager?

    var widgets: [AnyWidget] {
        return []
    }

    let date: Date

    init(date: Date, navigationManager: NavigationManager?) {
        self.date = date
        self.navigationManager = navigationManager
    }

    func makeMainContent() -> AnyView {
        AnyView(
            VStack {
                Text("Daily Page")
                    .font(.largeTitle)
                Text("Date: \(date.formatted(date: .long, time: .omitted))")
                Button("Go Back") {
                    navigationManager?.navigateBack()
                }
            }
            .padding()
        )
    }
}

