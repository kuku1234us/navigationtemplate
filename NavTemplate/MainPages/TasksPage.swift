import SwiftUI
import NavTemplateShared

struct TasksPage: Page {
    var navigationManager: NavigationManager?
    var widgets: [AnyWidget] { [] }
    
    @StateObject private var taskModel = TaskModel.shared
    
    private func handleTaskEdit(_ task: TaskItem) {
        print("Editing task: \(task.name)")
        // TODO: Implement edit modal
    }
    
    private func handleTaskDelete(_ task: TaskItem) {
        taskModel.deleteTask(task)
    }
    
    func makeMainContent() -> AnyView {
        AnyView(
            ZStack {
                // Background
                Image("batmanDim")
                    .resizable()
                    .ignoresSafeArea()
                    .overlay(.black.opacity(0.5))
                
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 0) {
                        HStack {
                            Text("Tasks")
                                .font(.largeTitle)
                                .fontWeight(.black)
                                .foregroundColor(Color("PageTitle"))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.horizontal)
                    }
                    .withSafeAreaTop()
                    .padding()
                    .backgroundBlur(radius: 10, opaque: true)
                    .background(
                        MeshGradient(
                            width: 3, height: 3,
                            points: [
                                [0.0,0.0], [0.5,0.0], [1.0,0.0],
                                [0.0,0.5], [0.5,0.5], [1.0,0.5],
                                [0.0,1.0], [0.5,1.0], [1.0,1.0]
                            ],
                            colors: [
                                Color("Background"),Color("Background"),.black,
                                .blue,Color("Background"),Color("Background"),
                                .blue,.blue,Color("Background"),                    
                            ]
                        )
                        .opacity(0.1)
                    )
                    
                    // Task List
                    TaskListView(
                        tasks: taskModel.tasks,
                        onEdit: handleTaskEdit,
                        onDelete: handleTaskDelete
                    )
                    .padding(.top)
                }
            }
            .onAppear {
                taskModel.loadAllTasks()
            }
        )
    }
} 