import Foundation
import Combine

@MainActor
public class TasksFilterSort: ObservableObject {
    public static let shared = TasksFilterSort()
    
    @Published public private(set) var filteredTasks: [TaskItem] = []
    
    private let taskModel = TaskModel.shared
    private let projectModel = ProjectModel.shared
    private let sortOrder = TaskSortOrder.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // Observe changes in tasks, filters, sort order, and filter toggles
        Publishers.CombineLatest4(
            taskModel.$tasks,
            projectModel.$settings,
            sortOrder.objectWillChange,
            taskModel.$filterToggles
        )
        .receive(on: RunLoop.main)
        .sink { [weak self] _ in
            self?.updateFilteredTasks()
        }
        .store(in: &cancellables)
        
        // Also observe TaskModel directly for any other changes
        taskModel.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateFilteredTasks()
            }
            .store(in: &cancellables)
        
        // Initial update
        updateFilteredTasks()
    }
    
    private func updateFilteredTasks() {
        // First filter tasks by selected projects
        var tasks = taskModel.tasks.filter { task in
            guard let project = projectModel.getProject(withId: task.projId) else {
                return false
            }            
            return projectModel.isProjectSelected(project.projId)
        }
        
        // Then apply filter toggles
        let toggles = taskModel.filterToggles
        if !toggles.priorities.isEmpty || !toggles.statuses.isEmpty {
            tasks = tasks.filter { task in
                // If priorities are selected, task must match one of them
                let priorityMatch = toggles.priorities.isEmpty || toggles.priorities.contains(task.priority)
                
                // If statuses are selected, task must match one of them
                let statusMatch = toggles.statuses.isEmpty || toggles.statuses.contains(task.taskStatus)
                
                // Task must match both conditions
                return priorityMatch && statusMatch
            }
        }
        
        // Finally apply sort order
        filteredTasks = taskModel.sortTasks(tasks)
    }
} 