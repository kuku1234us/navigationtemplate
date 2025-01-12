// NavTemplate/MainPages/TasksPage.swift

import SwiftUI
import NavTemplateShared

struct TasksPage: Page {
    var navigationManager: NavigationManager?
    
    // Create stable ID
    private let rightSheetId = UUID()
    
    var widgets: [AnyWidget] {
        // Right sheet setup
        let rightSideSheet = SideSheet(
            id: rightSheetId,
            content: {
                FilterSidesheet()
            },
            direction: .rightToLeft
        )

        let rightGestureHandler = DragGestureHandler(
            proxy: rightSideSheet.proxy,
            direction: .rightToLeft
        )

        let rightWidget = WidgetWithGesture(
            widget: rightSideSheet,
            gesture: rightGestureHandler
        )

        return [AnyWidget(rightWidget)]
    }
    
    @StateObject private var taskModel = TaskModel.shared
    @State private var showSortMenu = false
    @State private var headerFrame: CGRect = .zero    
    @State private var showTaskEditor = false
    @State private var taskToEdit: TaskItem?
    @State private var searchText = ""  // Add search text state
    
    private func handleTaskEdit(_ task: TaskItem) {
        taskToEdit = task
        showTaskEditor = true
    }
    
    private func handleTaskDelete(_ task: TaskItem) {
        taskModel.deleteTask(task)
    }
    
    private func handleNewTask() {
        taskToEdit = nil  // Ensure we're creating a new task
        showTaskEditor = true
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
                    // Header with search
                    TaskHeaderView(
                        showSortMenu: $showSortMenu,
                        searchText: $searchText  // Pass search text binding
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
                        onEdit: handleTaskEdit,
                        onDelete: handleTaskDelete,
                        searchText: $searchText  // Pass the binding
                    )
                    .padding(.top)
                }
                
                AddTaskButton(onTap: handleNewTask)

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

                // Task Editor Bottom Sheet
                if showTaskEditor {
                    BottomSheet(isPresented: $showTaskEditor) {
                        TaskEditor(task: taskToEdit, isPresented: $showTaskEditor)
                    }
                    .background(
                        Color.black.opacity(0.1)
                            .ignoresSafeArea()
                            .onTapGesture {
                                showTaskEditor = false
                            }
                    )
                }
            }
            .animation(.spring(duration: 0.3), value: showSortMenu)
            .onAppear {
                taskModel.loadAllTasks()
                // Process any pending task updates from widget
                TaskModel.shared.processPendingTaskUpdates()
            }
            .onDisappear {
                PropertyProxyFactory.shared.remove(id: rightSheetId)
                NavigationState.shared.setActiveWidgetId(nil)
            }
        )
    }
} 