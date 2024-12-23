// NavTemplate/MainPages/TasksPage.swift

import SwiftUI
import NavTemplateShared

struct TasksPage: Page {
    var navigationManager: NavigationManager?
    var widgets: [AnyWidget] { [] }
    
    @StateObject private var taskModel = TaskModel.shared
    @State private var showSortMenu = false
    @State private var headerFrame: CGRect = .zero    
    
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
                    TaskHeaderView(
                        showSortMenu: $showSortMenu
                    )
                    .background(
                        GeometryReader { geo in
                            Color.clear
                                .onAppear {
                                    DispatchQueue.main.async {
                                        self.headerFrame = geo.frame(in: .global)
                                    }
                                }
                        }
                    )
                    
                    // Task List
                    TaskListView(
                        tasks: taskModel.tasks,
                        onEdit: handleTaskEdit,
                        onDelete: handleTaskDelete
                    )
                    .padding(.top)
                }
                
                AddTaskButton()

                // Sort Menu Overlay
                if showSortMenu {
                    ZStack {
                        // Overlay for dismissing
                        Color.black.opacity(0.001)
                            .ignoresSafeArea()
                            .onTapGesture {
                                showSortMenu = false
                            }

                        HStack {
                            Spacer()
                            VStack {
                                SortMenu(
                                    onDismiss: {
                                        showSortMenu = false
                                    }
                                )
                                .onDisappear {
                                    showSortMenu = false
                                }
                                .padding(.top, self.headerFrame.maxY )
                                
                                Spacer()
                            }                            
                        }
                        .animation(.spring(duration: 0.3), value: showSortMenu)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }
            .animation(.spring(duration: 0.3), value: showSortMenu)
            .onAppear {
                taskModel.loadAllTasks()
            }
        )
    }
} 