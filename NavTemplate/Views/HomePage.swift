// HomePage.swift

import SwiftUI

struct HomePage: Page {
    
    var navigationManager: NavigationManager?

    // Create stable ID for sidesheet
    private let leftSheetId = UUID()
    
    var widgets: [AnyWidget] {
        // Left sheet setup
        let leftSideSheet = SideSheet(
            id: leftSheetId,
            content: {
                HomeLeftSidesheetView()
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
        
        return [AnyWidget(leftWidget)]
    }

    init(navigationManager: NavigationManager?) {
        self.navigationManager = navigationManager
    }

    func makeMainContent() -> AnyView {
        AnyView(
            ViewWithBottomMenu(items: [
                MenuBarItem(
                    unselectedIcon: "house",
                    selectedIcon: "house.fill",
                    targetView: DashboardLinksView(navigationManager: navigationManager).makeView()
                ),
                MenuBarItem(
                    unselectedIcon: "sun.horizon",
                    selectedIcon: "sun.horizon.fill",
                    targetView: AnyView(
                        ActivitiesPage(
                            navigationManager: navigationManager
                        )
                    )
                ),
                MenuBarItem(
                    unselectedIcon: "book",
                    selectedIcon: "book.fill",
                    targetView: AnyView(
                        BookPage(
                            navigationManager: navigationManager,
                            title: "Sample Book",
                            author: "John Doe"
                        )
                    )
                ),
                MenuBarItem(
                    unselectedIcon: "calendar",
                    selectedIcon: "calendar.circle.fill",
                    targetView: AnyView(
                        DailyPage(
                            date: Date(),
                            navigationManager: navigationManager
                        )
                    )
                ),
                MenuBarItem(
                    unselectedIcon: "folder",
                    selectedIcon: "folder.fill",
                    targetView: AnyView(
                        iCloudPage(
                            navigationManager: navigationManager
                        )
                    )
                )
            ])
            .onDisappear {
                print(">>>>> HomePage cleanup")
                PropertyProxyFactory.shared.remove(id: leftSheetId)
                NavigationState.shared.setActiveWidgetId(nil)
            }
        )
    }
}

