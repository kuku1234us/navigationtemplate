import Foundation
import SwiftUI
import Combine
import WidgetKit

public enum TaskStatus: String, Codable {
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
    
    // Convert from Character if needed
    public init(_ char: Character) {
        self = TaskStatus(rawValue: String(char)) ?? .notStarted
    }
    
    // Helper to get next status in cycle
    public static func nextTaskStatus(_ current: TaskStatus) -> TaskStatus {
        switch current {
        case .notStarted: return .inProgress
        case .inProgress: return .completed
        case .completed: return .notStarted
        }
    }
    
    // Convenience method on instance
    public func next() -> TaskStatus {
        TaskStatus.nextTaskStatus(self)
    }
}

public struct TaskItem: Identifiable {
    public let id: Int64
    public var name: String
    public var taskStatus: TaskStatus
    public var priority: TaskPriority
    public var projId: Int64
    public var dueDate: Date?
    public var tags: [String]
    public var createTime: Date
    
    public init(
        id: Int64,
        name: String,
        taskStatus: TaskStatus,
        priority: TaskPriority,
        projId: Int64,
        dueDate: Date? = nil,
        tags: [String] = [],
        createTime: Date
    ) {
        self.id = id
        self.name = name
        self.taskStatus = taskStatus
        self.priority = priority
        self.projId = projId
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

public struct WidgetTaskItem: Codable {
    public let taskId: Int64
    public let name: String
    public let priority: String
    public var status: String
    public let iconImageName: String
    
    public init(from task: TaskItem, iconName: String) {
        self.taskId = task.id
        self.name = task.name
        self.priority = task.priority.rawValue
        self.status = task.taskStatus.rawValue
        self.iconImageName = iconName
    }
    
    public init(taskId: Int64, name: String, priority: String, status: String, iconImageName: String) {
        self.taskId = taskId
        self.name = name
        self.priority = priority
        self.status = status
        self.iconImageName = iconImageName
    }
}

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
    
    private let maxWidgetTasks = 25
    
    private init() {
        // Load filter toggles from UserDefaults
        self.filterToggles = Self.loadFilterToggles()
        
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
        return projectModel.getProject(withId: task.projId)
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
        // Set up deferred UI update
        defer {
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
        
        do {
            let markdownFiles = try projectFileManager.findAllMarkdownFiles()
            var allTasks: [TaskItem] = []
            
            for fileURL in markdownFiles {
                // Try to read the file as a project file
                if let (content, projId) = try projectFileManager.readProjectFile(fileURL) {
                    let projectName = fileURL.deletingPathExtension().lastPathComponent
                    
                    // Parse tasks from the content
                    if let tasks = projectFileManager.parseTasksFromContent(
                        content,
                        projId: projId
                    ) {
                        allTasks.append(contentsOf: tasks)
                    }
                }
            }
            
            self.tasks = allTasks
            self.applySortOrder(TaskSortOrder.shared.currentOrder)
            
            // Update widget tasks after loading
            updateWidgetTasks()
            
        } catch {
            print("Error loading tasks: \(error)")
        }
    }
    
    public func deleteTask(_ task: TaskItem) {
        defer {
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
        
        // Remove from file
        do {
            try projectFileManager.removeTask(task)  // ProjectFileManager now uses projId internally
        } catch {
            print("Error removing task from file: \(error)")
            return
        }
        
        // Remove from memory
        tasks.removeAll { $0.id == task.id }
        
        // Update widget
        updateWidgetTasks()
    }
    
    public func updateTaskName(_ task: TaskItem, newName: String) {
        // Skip if name hasn't changed
        guard task.name != newName else { return }
        
        defer {
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
            // Update widget after task change
            updateWidgetTasks()
        }
        
        do {
            try projectFileManager.updateTaskName(task, newName: newName)
            if let index = self.tasks.firstIndex(where: { $0.id == task.id }) {
                var updatedTask = task
                updatedTask.name = newName
                self.tasks[index] = updatedTask
            }
        } catch {
            print("Error updating task name: \(error)")
        }
    }
    
    public func updateTaskStatus(_ task: TaskItem, status: TaskStatus) {
        defer {
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
            // Update widget after task change
            updateWidgetTasks()
        }
        
        do {
            try projectFileManager.updateTaskStatus(task, status: status)
            if let index = self.tasks.firstIndex(where: { $0.id == task.id }) {
                var updatedTask = task
                updatedTask.taskStatus = status
                self.tasks[index] = updatedTask
            }
        } catch {
            print("Error updating task status: \(error)")
        }
    }
    
    public func taskToText(_ task: TaskItem) -> String {
        var components: [String] = []
        
        // 1. Checkbox with status
        components.append("- [\(task.taskStatus.rawValue)]")
        
        // 2. Task Name (escaped)
        let escapedName = task.name
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "#", with: "\\#")
        components.append(escapedName)
        
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
        defer {
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
        
        // Add to memory
        tasks.insert(task, at: 0)  // Insert at beginning for immediate visibility
        applySortOrder(TaskSortOrder.shared.currentOrder)  // Re-sort if needed
        
        // Add to file
        do {
            let taskText = taskToText(task)
            if let project = projectModel.getProject(withId: task.projId) {
                try projectFileManager.appendTaskToFile(project.filePath, taskText: taskText)
            }
        } catch {
            print("Error adding task to file: \(error)")
        }
        
        updateWidgetTasks()
    }
    
    public func updateTask(_ task: TaskItem, newName: String, newPriority: TaskPriority, newProjId: Int64) {
        defer {
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
        
        // Create updated task
        var updatedTask = task
        updatedTask.name = newName
        updatedTask.priority = newPriority
        updatedTask.projId = newProjId
        
        // Check if project changed
        let isProjectChanged = task.projId != newProjId
        
        if isProjectChanged {
            do {
                // Remove from old project
                try projectFileManager.removeTask(task)
                
                // Add to new project
                if let newProject = projectModel.getProject(withId: newProjId) {
                    try projectFileManager.appendTaskToFile(newProject.filePath, taskText: taskToText(updatedTask))
                }
            } catch {
                print("Error moving task to new project: \(error)")
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
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index] = updatedTask
            applySortOrder(TaskSortOrder.shared.currentOrder)
        }
        
        updateWidgetTasks()
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
                guard let proj1 = projectModel.getProject(withId: task1.projId),
                      let proj2 = projectModel.getProject(withId: task2.projId) else {
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
            let projectLastTaskTime: [Int64: Date] = Dictionary(
                grouping: tasks,
                by: { $0.projId }
            ).mapValues { tasks in
                tasks.map { $0.createTime }.max() ?? Date.distantPast
            }
            
            sortedTasks.sort { task1, task2 in
                let proj1Time = projectLastTaskTime[task1.projId] ?? Date.distantPast
                let proj2Time = projectLastTaskTime[task2.projId] ?? Date.distantPast
                
                if task1.projId == task2.projId {
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
    
    /// Updates the WidgetTasks in UserDefaults for widget display
    private func updateWidgetTasks() {
        let defaults = UserDefaults(suiteName: "group.us.kothreat.NavTemplate")
        
        // Get all non-completed tasks sorted by creation time (newest first)
        let activeTasks = tasks.filter { $0.taskStatus != .completed }
            .sorted { $0.createTime > $1.createTime }
        
        // First, get urgent tasks
        let urgentTasks = activeTasks.filter { $0.priority == .urgent }
            .prefix(maxWidgetTasks)
        
        // Calculate remaining slots
        let remainingSlots = maxWidgetTasks - urgentTasks.count
        
        // Get non-urgent tasks if there are slots remaining
        let nonUrgentTasks = remainingSlots > 0 ? 
            activeTasks.filter { $0.priority != .urgent }
                .prefix(remainingSlots) : []
        
        // Combine tasks
        let widgetTasks = Array(urgentTasks) + Array(nonUrgentTasks)
        
        // Create WidgetTaskItems
        let serializableTasks = widgetTasks.map { task in
            let iconName = projectModel.getProject(withId: task.projId)?.icon ?? "inbox.png"
            return WidgetTaskItem(from: task, iconName: iconName)
        }
        
        // Save to UserDefaults
        if let encoded = try? JSONEncoder().encode(serializableTasks) {
            defaults?.set(encoded, forKey: "WidgetTasks")
        }
        
        // Trigger widget refresh
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    // Add these methods to handle widget task updates
    public static func pushTaskUpdateToQueue(_ widgetTask: WidgetTaskItem, newStatus: String) {
        let defaults = UserDefaults(suiteName: "group.us.kothreat.NavTemplate")
        
        // 1. Update PendingTaskUpdates queue
        var pendingUpdates: [WidgetTaskItem] = []
        if let data = defaults?.data(forKey: "PendingTaskUpdates"),
           let existing = try? JSONDecoder().decode([WidgetTaskItem].self, from: data) {
            pendingUpdates = existing
        }
        
        // Create new instance with updated status
        let updatedTask = WidgetTaskItem(
            taskId: widgetTask.taskId,
            name: widgetTask.name,
            priority: widgetTask.priority,
            status: newStatus,
            iconImageName: widgetTask.iconImageName
        )
        
        // Add new update to queue
        pendingUpdates.append(updatedTask)
        
        // Save updated queue
        if let encoded = try? JSONEncoder().encode(pendingUpdates) {
            defaults?.set(encoded, forKey: "PendingTaskUpdates")
        }
        
        // 2. Update WidgetTasks
        if let data = defaults?.data(forKey: "WidgetTasks"),
           var widgetTasks = try? JSONDecoder().decode([WidgetTaskItem].self, from: data) {
            // Find and update the task
            if let index = widgetTasks.firstIndex(where: { $0.taskId == widgetTask.taskId }) {
                widgetTasks[index] = updatedTask
                
                // Save back to UserDefaults
                if let encoded = try? JSONEncoder().encode(widgetTasks) {
                    defaults?.set(encoded, forKey: "WidgetTasks")
                }
            }
        }
        
        // 3. Trigger widget refresh
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    public func processPendingTaskUpdates() {
        let defaults = UserDefaults(suiteName: "group.us.kothreat.NavTemplate")
        
        // Get pending updates
        guard let data = defaults?.data(forKey: "PendingTaskUpdates"),
              let pendingUpdates = try? JSONDecoder().decode([WidgetTaskItem].self, from: data) else {
            return
        }
        
        // Process all updates first
        var successfulUpdates: [WidgetTaskItem] = []
        for updatedTask in pendingUpdates {
            // Find corresponding TaskItem by taskId
            if let index = tasks.firstIndex(where: { $0.id == updatedTask.taskId }) {
                do {
                    let taskItem = tasks[index]
                    let newStatus = TaskStatus(rawValue: updatedTask.status) ?? .notStarted
                    try projectFileManager.updateTaskStatus(taskItem, status: newStatus)
                    successfulUpdates.append(updatedTask)
                } catch {
                    Logger.shared.error("Failed to process pending task update: \(error)")
                }
            }
        }
        
        // Clear pending queue first to avoid recursive calls
        defaults?.removeObject(forKey: "PendingTaskUpdates")
        
        // If we processed any updates successfully
        if !successfulUpdates.isEmpty {
            // Update tasks array
            for updatedTask in successfulUpdates {
                if let index = tasks.firstIndex(where: { $0.id == updatedTask.taskId }) {
                    var task = tasks[index]
                    task.taskStatus = TaskStatus(rawValue: updatedTask.status) ?? .notStarted
                    tasks[index] = task
                }
            }
            
            // Update widget
            updateWidgetTasks()
            
            // Notify UI of changes
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }
    
    /// Loads widget tasks from UserDefaults (used by widget)
    public static func loadWidgetTasksFromDefaults() -> [WidgetTaskItem]? { 
        let defaults = UserDefaults(suiteName: "group.us.kothreat.NavTemplate")
        
        guard let data = defaults?.data(forKey: "WidgetTasks"),
              let widgetTasks = try? JSONDecoder().decode([WidgetTaskItem].self, from: data)
        else {
            return nil
        }
        
        return widgetTasks
    }
    
    public func updateAllTasks(_ newTasks: [TaskItem]) {
        self.tasks = newTasks
        self.applySortOrder(TaskSortOrder.shared.currentOrder)
        
        // Update widget tasks after loading
        updateWidgetTasks()
        
        // Notify UI of changes
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
    
    public func getProjectName(for task: TaskItem) -> String {
        if let project = projectModel.getProject(withId: task.projId) {
            return project.projectName
        }
        return "Unknown Project"
    }
} 