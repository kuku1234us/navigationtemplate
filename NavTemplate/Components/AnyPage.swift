// AnyPage.swift

import SwiftUI

struct AnyPage: Identifiable, View, Hashable {
    let id = UUID()
    private let _view: AnyView

    init<P: Page>(_ page: P) {
        self._view = AnyView(page)
    }

    var body: some View {
        _view
    }

    static func == (lhs: AnyPage, rhs: AnyPage) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
