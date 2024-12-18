// MenuPage.swift

import SwiftUI

struct MenuPage: Page {
    var navigationManager: NavigationManager?
    var widgets: [AnyWidget] { [] }  // Empty, not using widgets
    
    init(navigationManager: NavigationManager?) {
        self.navigationManager = navigationManager
    }
    
    func makeMainContent() -> AnyView {
        AnyView(
            ViewWithBottomMenu(items: [
                MenuBarItem(
                    unselectedIcon: "house",
                    selectedIcon: "house.fill",
                    targetView: AnyView(Text("Home View").font(.largeTitle))
                ),
                MenuBarItem(
                    unselectedIcon: "magnifyingglass",
                    selectedIcon: "magnifyingglass.circle.fill",
                    targetView: AnyView(Text("Search View").font(.largeTitle))
                ),
                MenuBarItem(
                    unselectedIcon: "person",
                    selectedIcon: "person.fill",
                    targetView: AnyView(Text("Profile View").font(.largeTitle))
                )
            ])
        )
    }
}

