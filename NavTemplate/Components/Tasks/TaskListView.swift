import SwiftUI
import NavTemplateShared

struct KeyboardAwareModifier: ViewModifier {
    @Binding var keyboardHeight: CGFloat
    let onKeyboardShow: () -> Void
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                NotificationCenter.default.addObserver(
                    forName: UIResponder.keyboardWillShowNotification,
                    object: nil,
                    queue: .main
                ) { notification in
                    let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect ?? .zero
                    keyboardHeight = keyboardFrame.height
                    onKeyboardShow()
                }
                
                NotificationCenter.default.addObserver(
                    forName: UIResponder.keyboardWillHideNotification,
                    object: nil,
                    queue: .main
                ) { _ in
                    keyboardHeight = 0
                }
            }
    }
}

struct TaskListView: View {
    @StateObject private var tasksFilterSort = TasksFilterSort.shared
    let onEdit: (TaskItem) -> Void
    let onDelete: (TaskItem) -> Void
    @State private var keyboardHeight: CGFloat = 0
    @State private var editingTaskId: Int64?
    @Binding var searchText: String
    
    private var filteredTasks: [TaskItem] {
        if searchText.isEmpty {
            return tasksFilterSort.filteredTasks
        }
        
        let searchQuery = searchText.lowercased()
        return tasksFilterSort.filteredTasks.filter { task in
            let nameMatch = task.name.lowercased().contains(searchQuery)
            
            let projectMatch = ProjectModel.shared.getProject(atPath: task.projectFilePath)?
                .projectName
                .lowercased()
                .contains(searchQuery) ?? false
            
            return nameMatch || projectMatch
        }
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 5) {
                    ForEach(filteredTasks, id: \.id) { task in
                        TaskItemView(
                            task: task,
                            onEdit: { onEdit(task) },
                            onDelete: { onDelete(task) }
                        )
                        .id(task.id)
                        .onChange(of: task.name) { oldValue, newValue in
                            editingTaskId = task.id
                            withAnimation {
                                proxy.scrollTo(task.id, anchor: .center)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, keyboardHeight + 100)
            }
            .modifier(KeyboardAwareModifier(
                keyboardHeight: $keyboardHeight,
                onKeyboardShow: {
                    if let id = editingTaskId {
                        withAnimation {
                            proxy.scrollTo(id, anchor: .center)
                        }
                    }
                }
            ))
        }
    }
}

