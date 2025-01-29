// HomePage.swift

import SwiftUI
import NavTemplateShared

struct HomePage: Page {
    
    var navigationManager: NavigationManager?

    // Create stable ID for sidesheet
    private let leftSheetId = UUID()
    private var menuItems: [MenuBarItem] = []

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
        
        // Initialize menu items
        menuItems = [
            MenuBarItem(
                id: 1,
                name: "Maintenance",
                unselectedIcon: "wrench.and.screwdriver",
                selectedIcon: "wrench.and.screwdriver.fill",
                targetView: AnyView(
                    MaintenancePage(
                        navigationManager: navigationManager
                    )
                )
            ),
            MenuBarItem(
                id: 2,
                name: "Tasks",
                unselectedIcon: "checklist",
                selectedIcon: "checklist.checked",
                targetView: AnyView(
                    TasksPage(
                        navigationManager: navigationManager
                    )
                )
            ),
            MenuBarItem(
                id: 3,
                name: "Activities",
                unselectedIcon: "sun.horizon",
                selectedIcon: "sun.horizon.fill",
                targetView: AnyView(
                    ActivitiesPage(
                        navigationManager: navigationManager
                    )
                )
            ),
            MenuBarItem(
                id: 4,
                name: "Calendar",
                unselectedIcon: "calendar",
                selectedIcon: "calendar.badge.clock",
                targetView: AnyView(
                    CalendarPage(
                        navigationManager: navigationManager
                    )
                )
            ),
            MenuBarItem(
                id: 5,
                name: "Year",
                unselectedIcon: "square.grid.3x3",
                selectedIcon: "square.grid.3x3.fill",
                targetView: AnyView(
                    YearPage(
                        navigationManager: navigationManager
                    )
                )
            ),
            MenuBarItem(
                id: 6,
                name: "Test",
                unselectedIcon: "testtube.2",
                selectedIcon: "testtube.2",
                targetView: AnyView(TestPage())
            )
        ]
        
        // Save menu items to MenuModel
        MenuModel.shared.setMenuItems(menuItems)
    }

    func makeMainContent() -> AnyView {
        return AnyView(
            ViewWithBottomMenu(items: menuItems)
        )
    }
}

