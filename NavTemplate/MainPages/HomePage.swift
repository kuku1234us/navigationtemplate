// HomePage.swift

import SwiftUI

struct HomePage: Page {
    
    var navigationManager: NavigationManager?

    // Create stable ID for sidesheet
    private let leftSheetId = UUID()

    var widgets: [AnyWidget] {
        return []  // No widgets for now
    }

    // var widgets: [AnyWidget] {
    //     // Left sheet setup
    //     let leftSideSheet = SideSheet(
    //         id: leftSheetId,
    //         content: {
    //             HomeLeftSidesheetView()
    //         },
    //         direction: .leftToRight
    //     )
        
    //     let leftGestureHandler = DragGestureHandler(
    //         proxy: leftSideSheet.proxy,
    //         direction: .leftToRight
    //     )
        
    //     let leftWidget = WidgetWithGesture(
    //         widget: leftSideSheet,
    //         gesture: leftGestureHandler
    //     )
        
    //     return [AnyWidget(leftWidget)]
    // }

    init(navigationManager: NavigationManager?) {
        self.navigationManager = navigationManager
    }

    func makeMainContent() -> AnyView {
        AnyView(
            ViewWithBottomMenu(items: [
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
                    unselectedIcon: "square.grid.3x3",
                    selectedIcon: "square.grid.3x3.fill",
                    targetView: AnyView(
                        YearPage(
                            navigationManager: navigationManager
                        )
                    )
                ),
                MenuBarItem(
                    unselectedIcon: "testtube.2",
                    selectedIcon: "testtube.2",
                    targetView: AnyView(TestPage())
                )
             
            ])
            .onDisappear {
                // print(">>>>> HomePage cleanup")
                // PropertyProxyFactory.shared.remove(id: leftSheetId)
                // NavigationState.shared.setActiveWidgetId(nil)
            }
        )
    }
}

