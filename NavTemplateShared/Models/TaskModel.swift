import Foundation
import SwiftUI
import Combine

public struct TaskItem: Identifiable {
    public let id: Int64  // Unix timestamp as ID
    public var name: String
    public var isCompleted: Bool
    public var priority: TaskPriority
    public var projectName: String
    public var projectFilePath: String
    public var dueDate: Date?
    public var tags: [String]
    public var createTime: Date
    
    public init(
        id: Int64,
        name: String,
        isCompleted: Bool,
        priority: TaskPriority,
        projectName: String,
        projectFilePath: String,
        dueDate: Date? = nil,
        tags: [String] = [],
        createTime: Date
    ) {
        self.id = id
        self.name = name
        self.isCompleted = isCompleted
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
    private let projectFileManager = ProjectFileManager.shared
    
    public static let shared = TaskModel()
    private init() {}
    
    public func loadAllTasks() {
        do {
            let projectFiles = try projectFileManager.findAllProjectFiles()
            var allTasks: [TaskItem] = []
            
            for projectFile in projectFiles {
                if let tasks = try projectFileManager.parseTasksFromFile(projectFile) {
                    allTasks.append(contentsOf: tasks)
                }
            }
            
            // Sort by creation time, newest first
            allTasks.sort { $0.createTime > $1.createTime }
            
            DispatchQueue.main.async {
                self.tasks = allTasks
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
    
    public func updateTaskCompletion(_ task: TaskItem, isCompleted: Bool) {
        do {
            try projectFileManager.updateTaskCompletion(task, isCompleted: isCompleted)
            DispatchQueue.main.async {
                if let index = self.tasks.firstIndex(where: { $0.id == task.id }) {
                    var updatedTask = task
                    updatedTask.isCompleted = isCompleted
                    self.tasks[index] = updatedTask
                }
            }
        } catch {
            print("Error updating task completion: \(error)")
        }
    }
} 