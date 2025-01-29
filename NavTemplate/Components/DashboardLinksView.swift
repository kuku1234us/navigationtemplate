import SwiftUI

struct DashboardLinksView {
    let navigationManager: NavigationManager?
    
    // Make it return AnyView to match Page protocol
    func makeView() -> AnyView {
        AnyView(
            VStack(spacing: 5) {
                CircleButton(icon: "house", iconColor: Color("Accent"), buttonColor: Color("SideSheetBg"))
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
                Button("Browse Files") {
                    let fileBrowserPage = FileBrowserPage(
                        navigationManager: navigationManager
                    )
                    navigationManager?.navigate(to: AnyPage(fileBrowserPage))
                }

                Button("Activities") {
                    let activitiesPage = ActivitiesPage(
                        navigationManager: navigationManager
                    )
                    navigationManager?.navigate(to: AnyPage(activitiesPage))
                }
            }
            .padding()
        )
    }
} 