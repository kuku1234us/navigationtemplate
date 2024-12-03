// DailyPage.swift

import SwiftUI

struct DailyPage: Page {
    var id: UUID = UUID()
    var navigationManager: NavigationManager?
    var widgets: [any Widget] = []
    var gestures: [AnyGesture<()>] = []

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
        )
    }
}
