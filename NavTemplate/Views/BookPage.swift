// BookPage.swift

import SwiftUI
import Combine

class BookPageViewModel: ObservableObject {
    @Published var widgets: [any Widget] = []
    let title: String
    let author: String
    weak var navigationManager: NavigationManager?
    
    private var cancellables = Set<AnyCancellable>()
    
    @Published var debugText: String = "No gesture detected"
    @Published var translation: CGPoint = .zero
    
    init(title: String, author: String, navigationManager: NavigationManager?) {
        self.title = title
        self.author = author
        self.navigationManager = navigationManager
        setupWidgets()
    }
    
    private func setupWidgets() {
        print("Setting up widgets")
        var sheet: SideSheet<AnyView>? = nil
        
        sheet = SideSheet {
            VStack {
                Text("Book Details")
                    .font(.largeTitle)
                Text("Title: \(self.title)")
                Text("Author: \(self.author)")
                Button("Close") {
                    sheet?.setActive(false)
                }
            }
            .padding()
            .eraseToAnyView()
        }
        
        if let sheet = sheet {
            print("Sheet created with gesture: \(sheet.gesture != nil)")
            self.widgets = [sheet]
            
            sheet.gestureHandler.$debugText
                .sink { [weak self] text in
                    self?.debugText = text
                }
                .store(in: &cancellables)
            
            sheet.gestureHandler.$translation
                .sink { [weak self] translation in
                    self?.translation = translation
                }
                .store(in: &cancellables)
        }
    }
}

struct BookPage: Page {
    var id: UUID = UUID()
    var navigationManager: NavigationManager?
    
    var widgets: [any Widget] {
        get { viewModel.widgets }
        set { viewModel.widgets = newValue }
    }
    
    @StateObject private var viewModel: BookPageViewModel
    
    init(title: String, author: String, navigationManager: NavigationManager?) {
        _viewModel = StateObject(wrappedValue: BookPageViewModel(
            title: title,
            author: author,
            navigationManager: navigationManager
        ))
        self.navigationManager = navigationManager
    }
    
    func makeMainContent() -> AnyView {
        AnyView(
            VStack(spacing: 20) {
                Text("Book Page")
                    .font(.largeTitle)
                Text("Title: \(viewModel.title)")
                Text("Author: \(viewModel.author)")
                
                // Debug information
                VStack(alignment: .leading, spacing: 10) {
                    Text("Debug Info:")
                        .font(.headline)
                    Text(viewModel.debugText)
                        .font(.system(.body, design: .monospaced))
                    Text("Translation: (\(viewModel.translation.x.rounded(), specifier: "%.1f"), \(viewModel.translation.y.rounded(), specifier: "%.1f"))")
                        .font(.system(.body, design: .monospaced))
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                
                Button("Go Back") {
                    navigationManager?.navigateBack()
                }
            }
            .padding()
        )
    }
}

extension View {
    func eraseToAnyView() -> AnyView {
        AnyView(self)
    }
}
