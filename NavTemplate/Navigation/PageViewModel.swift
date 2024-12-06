import SwiftUI
import Combine

class PageViewModel: ObservableObject {
    @Published var isBackButtonHidden: Bool = false
    private var cancellables = Set<AnyCancellable>()
    
    static let shared = PageViewModel()
    
    private init() {
        // Observe NavigationState.shared
        NavigationState.shared.objectWillChange
            .sink { [weak self] _ in
                self?.isBackButtonHidden = NavigationState.shared.isBackButtonHidden
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
} 