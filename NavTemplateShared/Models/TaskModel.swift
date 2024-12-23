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

public class TaskModel: ObservableObject {
    @Published public private(set) var tasks: [TaskItem] = []
    private let projectModel = ProjectModel.shared
    private let projectFileManager = ProjectFileManager.shared
    
    public static let shared = TaskModel()
    
    private init() {
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
            
            // Apply current sort order instead of default sort
            DispatchQueue.main.async {
                self.tasks = allTasks
                self.applySortOrder(TaskSortOrder.shared.currentOrder)
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
    
    private func applySortOrder(_ order: TaskSortOrderType) {
        switch order {
        case .taskCreationDesc:
            sortTasksByCreatedTime()
        case .projModifiedDesc:
            sortTasksByProjectModified()
        }
    }
} 