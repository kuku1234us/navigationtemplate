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
                    unselectedIcon: "checklist",
                    selectedIcon: "checklist.checked",
                    targetView: AnyView(
                        TasksPage(
                            navigationManager: navigationManager
                        )
                    )
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
                    unselectedIcon: "calendar",
                    selectedIcon: "calendar.badge.clock",
                    targetView: AnyView(
                        CalendarPage(
                            navigationManager: navigationManager
                        )
                    )
                ),
                MenuBarItem(
                    unselectedIcon: "testtube.2",
                    selectedIcon: "testtube.2",
                    targetView: AnyView(TestPage())
                ),
                MenuBarItem(
                    unselectedIcon: "wrench.and.screwdriver",
                    selectedIcon: "wrench.and.screwdriver.fill",
                    targetView: AnyView(
                        MaintenancePage(
                            navigationManager: navigationManager
                        )
                    )
                ),
                MenuBarItem(
                    unselectedIcon: "folder",
                    selectedIcon: "folder.fill",
                    targetView: AnyView(
                        iCloudPage()
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

