import Foundation
import SwiftUI
import Combine

public enum TaskStatus: String {
    case notStarted = " "
    case completed = "x"
    case inProgress = "/"
    
    public var icon: String {
        switch self {
        case .notStarted: return "square"
        case .completed: return "checkmark.square.fill"
        case .inProgress: return "square.lefthalf.filled"
        }
    }
    
    public init(statusChar: Character) {
        switch statusChar {
        case "x": self = .completed
        case "/": self = .inProgress
        default: self = .notStarted
        }
    }
}

public struct TaskItem: Identifiable {
    public let id: Int64
    public var name: String
    public var taskStatus: TaskStatus
    public var priority: TaskPriority
    public var projectName: String
    public var projectFilePath: String
    public var dueDate: Date?
    public var tags: [String]
    public var createTime: Date
    
    public init(
        id: Int64,
        name: String,
        taskStatus: TaskStatus,
        priority: TaskPriority,
        projectName: String,
        projectFilePath: String,
        dueDate: Date? = nil,
        tags: [String] = [],
        createTime: Date
    ) {
        self.id = id
        self.name = name
        self.taskStatus = taskStatus
        self.priority = priority
        self.projectName = projectName
        self.projectFilePath = projectFilePath
        self.dueDate = dueDate
        self.tags = tags
        self.createTime = createTime
    }
}

// Define the filter set structure
public struct TaskFilterToggleSet: Codable {
    public var priorities: Set<TaskPriority>
    public var statuses: Set<TaskStatus>
    
    public init(priorities: Set<TaskPriority> = [], statuses: Set<TaskStatus> = []) {
        self.priorities = priorities
        self.statuses = statuses
    }
}

// Make TaskPriority and TaskStatus Codable
extension TaskPriority: Codable {}
extension TaskStatus: Codable {}

public class TaskModel: ObservableObject {
    @Published public private(set) var tasks: [TaskItem] = []
    private let projectModel = ProjectModel.shared
    private let projectFileManager = ProjectFileManager.shared
    
    public static let shared = TaskModel()
    
    // Add filter toggle set
    @Published public private(set) var filterToggles: TaskFilterToggleSet {
        didSet {
            // Save to UserDefaults whenever it changes
            saveFilterToggles()
        }
    }
    
    private init() {
        // Load filter toggles from UserDefaults
        self.filterToggles = Self.loadFilterToggles()
        
        // projectModel.loadProjects()
        setupProjectObserver()
        setupSortOrderObserver()
        loadAllTasks()
    }
    
    private func setupProjectObserver() {
        projectModel.objectWillChange.sink { [weak self] _ in
            self?.loadAllTasks()
        }
        .store(in: &cancellables)
    }
    
    public func getProjectForTask(_ task: TaskItem) -> ProjectMetadata? {
        return projectModel.getProject(atPath: task.projectFilePath)
    }
    
    public func sortTasksByProjectModified() {
        DispatchQueue.main.async {
            self.tasks.sort { task1, task2 in
                let proj1 = self.getProjectForTask(task1)
                let proj2 = self.getProjectForTask(task2)
                
                // If projects have different modified times, sort by that
                if let time1 = proj1?.modifiedTime, let time2 = proj2?.modifiedTime,
                   time1 != time2 {
                    return time1 > time2
                }
                
                // If same project or modified times, sort by task creation time (desc)
                return task1.createTime > task2.createTime
            }
        }
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    public func loadAllTasks() {
        do {
            let projectFiles = try projectFileManager.findAllProjectFiles()
            var allTasks: [TaskItem] = []
            
            for projectFile in projectFiles {
                if let tasks = try projectFileManager.parseTasksFromFile(projectFile) {
                    allTasks.append(contentsOf: tasks)
                }
            }

            self.tasks = allTasks

            // Apply current sort order instead of default sort
            DispatchQueue.main.async {
                self.applySortOrder(TaskSortOrder.shared.currentOrder)
                self.objectWillChange.send()
            }
        } catch {
            print("Error loading tasks: \(error)")
        }
    }
    
    public func deleteTask(_ task: TaskItem) {
        do {
            try projectFileManager.removeTask(task)
            DispatchQueue.main.async {
                self.tasks.removeAll { $0.id == task.id }
            }
        } catch {
            print("Error deleting task: \(error)")
        }
    }
    
    public func updateTaskName(_ task: TaskItem, newName: String) {
        // Skip if name hasn't changed
        guard task.name != newName else { return }
        
        do {
            try projectFileManager.updateTaskName(task, newName: newName)
            DispatchQueue.main.async {
                if let index = self.tasks.firstIndex(where: { $0.id == task.id }) {
                    var updatedTask = task
                    updatedTask.name = newName
                    self.tasks[index] = updatedTask
                }
            }
        } catch {
            print("Error updating task name: \(error)")
        }
    }
    
    public func updateTaskStatus(_ task: TaskItem, status: TaskStatus) {
        do {
            try projectFileManager.updateTaskStatus(task, status: status)
            DispatchQueue.main.async {
                if let index = self.tasks.firstIndex(where: { $0.id == task.id }) {
                    var updatedTask = task
                    updatedTask.taskStatus = status
                    self.tasks[index] = updatedTask
                }
            }
        } catch {
            print("Error updating task status: \(error)")
        }
    }
    
    public func taskToText(_ task: TaskItem) -> String {
        var components: [String] = []
        
        // 1. Checkbox with status
        components.append("- [\(task.taskStatus.rawValue)]")
        
        // 2. Task Name
        components.append(task.name)
        
        // 3. Due Date (if exists)
        if let dueDate = task.dueDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            components.append("(due:: \(formatter.string(from: dueDate)))")
        }
        
        // 4. Tags
        if !task.tags.isEmpty {
            let tagString = task.tags.map { "#\($0)" }.joined(separator: " ")
            components.append(tagString)
        }
        
        // 5. Priority Level
        components.append("<span class=\"priority\">\(task.priority.rawValue)</span>")
        
        // 6. Creation Time (ID)
        components.append("<span class=\"createTime\">\(task.id)</span>")
        
        // Join all components with spaces
        return components.joined(separator: " ")
    }
    
    private func sortTasksByCreatedTime() {
        // Sort by creation time, newest first (descending)
        DispatchQueue.main.async {
            self.tasks.sort { task1, task2 in
                task1.createTime > task2.createTime
            }
        }
    }
    
    private func setupSortOrderObserver() {
        NotificationCenter.default.addObserver(
            forName: .taskSortOrderDidChange,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let sortOrder = notification.userInfo?["sortOrder"] as? TaskSortOrderType {
                self?.applySortOrder(sortOrder)
            }
        }
    }
    
    public func applySortOrder(_ order: TaskSortOrderType? = nil) {
        // Apply sorting
        tasks = sortTasks(tasks)
        
        // Force a UI update
        objectWillChange.send()
    }
    
    public func addTask(_ task: TaskItem) {
        // Add to memory
        DispatchQueue.main.async {
            self.tasks.insert(task, at: 0)  // Insert at beginning for immediate visibility
            self.applySortOrder(TaskSortOrder.shared.currentOrder)  // Re-sort if needed
        }
        
        // Add to file
        do {
            let taskText = taskToText(task)
            try projectFileManager.appendTaskToFile(task.projectFilePath, taskText: taskText)
        } catch {
            print("Error adding task to file: \(error)")
        }
    }
    
    public func updateTask(_ task: TaskItem, newName: String, newPriority: TaskPriority, newProjectPath: String) {
        // Create updated task
        var updatedTask = task
        updatedTask.name = newName
        updatedTask.priority = newPriority
        
        // Check if project changed
        let isProjectChanged = task.projectFilePath != newProjectPath
        
        if isProjectChanged {
            updatedTask.projectFilePath = newProjectPath
            if let project = projectModel.getProject(atPath: newProjectPath) {
                updatedTask.projectName = project.projectName
            }
            
            // Handle project change in files
            do {
                // 1. Remove from old project
                try projectFileManager.removeTaskFromFile(task.projectFilePath, taskId: task.id)
                
                // 2. Add to new project
                let newTaskText = taskToText(updatedTask)
                try projectFileManager.appendTaskToFile(newProjectPath, taskText: newTaskText)
            } catch {
                print("Error moving task between projects: \(error)")
                return
            }
        } else {
            // Update in same project file
            do {
                try projectFileManager.updateTask(updatedTask)
            } catch {
                print("Error updating task: \(error)")
                return
            }
        }
        
        // Update in memory
        DispatchQueue.main.async {
            if let index = self.tasks.firstIndex(where: { $0.id == task.id }) {
                self.tasks[index] = updatedTask
                // Force a UI update
                self.objectWillChange.send()
                self.applySortOrder(TaskSortOrder.shared.currentOrder)
            }
        }
    }
    
    // Methods to handle filter toggles
    private static func loadFilterToggles() -> TaskFilterToggleSet {
        if let data = UserDefaults.standard.data(forKey: "TaskFilterToggles"),
           let toggles = try? JSONDecoder().decode(TaskFilterToggleSet.self, from: data) {
            return toggles
        }
        return TaskFilterToggleSet()  // Return empty set if nothing saved
    }
    
    private func saveFilterToggles() {
        if let data = try? JSONEncoder().encode(filterToggles) {
            UserDefaults.standard.set(data, forKey: "TaskFilterToggles")
        }
    }
    
    // Public method to update toggles
    public func updateFilterToggles(priorities: Set<TaskPriority>? = nil, statuses: Set<TaskStatus>? = nil) {
        var newToggles = filterToggles
        if let priorities = priorities {
            newToggles.priorities = priorities
        }
        if let statuses = statuses {
            newToggles.statuses = statuses
        }
        filterToggles = newToggles
    }
    
    public func sortTasks(_ tasks: [TaskItem]) -> [TaskItem] {
        let sortOrder = TaskSortOrder.shared.currentOrder
        var sortedTasks = tasks
        
        switch sortOrder {
        case .taskCreationDesc:
            // Sort by task creation time (descending)
            sortedTasks.sort { $0.createTime > $1.createTime }
            
        case .priorityDesc:
            // Sort by priority (descending), then by creation time (descending)
            sortedTasks.sort { task1, task2 in
                if task1.priority != task2.priority {
                    return task1.priority.isHigherThan(task2.priority)
                }
                return task1.createTime > task2.createTime
            }
            
        case .projSelectedDesc:
            // Sort by project order from FilterSidesheet, then by priority, then by task creation time
            sortedTasks.sort { task1, task2 in
                guard let proj1 = projectModel.getProject(atPath: task1.projectFilePath),
                      let proj2 = projectModel.getProject(atPath: task2.projectFilePath) else {
                    return false
                }
                
                let order1 = projectModel.settings.projectOrder.firstIndex(of: proj1.projId) ?? Int.max
                let order2 = projectModel.settings.projectOrder.firstIndex(of: proj2.projId) ?? Int.max
                
                if order1 != order2 {
                    return order1 < order2
                }
                
                if task1.priority != task2.priority {
                    return task1.priority.isHigherThan(task2.priority)
                }
                
                // If same priority, sort by creation time (descending)
                return task1.createTime > task2.createTime
            }
            
        case .projModifiedDesc:
            // Get the last task creation time for each project
            let projectLastTaskTime: [String: Date] = Dictionary(
                grouping: tasks,
                by: { $0.projectFilePath }
            ).mapValues { tasks in
                tasks.map { $0.createTime }.max() ?? Date.distantPast
            }
            
            sortedTasks.sort { task1, task2 in
                let proj1Time = projectLastTaskTime[task1.projectFilePath] ?? Date.distantPast
                let proj2Time = projectLastTaskTime[task2.projectFilePath] ?? Date.distantPast
                
                if task1.projectFilePath == task2.projectFilePath {
                    if task1.priority != task2.priority {
                        return task1.priority.isHigherThan(task2.priority)
                    }
                    // If same priority, sort by creation time (descending)
                    return task1.createTime > task2.createTime
                }
                
                return proj1Time > proj2Time
            }
        }
        
        return sortedTasks
    }
} 