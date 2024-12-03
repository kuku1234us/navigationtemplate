// NavigationManager.swift

import SwiftUI

class NavigationManager: ObservableObject {
    @Published var navigationPath: [AnyPage] = []

    func navigate(to page: AnyPage) {
        navigationPath.append(page)
    }

    func navigateBack() {
        if !navigationPath.isEmpty {
            navigationPath.removeLast()
        }
    }

    func navigateToRoot() {
        navigationPath.removeAll()
    }
}
