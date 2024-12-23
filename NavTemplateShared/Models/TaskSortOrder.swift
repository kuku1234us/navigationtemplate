import Foundation
import Combine

public enum TaskSortOrderType: String {
    case taskCreationDesc = "Task Creation (Newest First)"
    case projModifiedDesc = "Project Modified (Newest First)"
    
    public var icon: String {
        switch self {
        case .taskCreationDesc:
            return "calendar.badge.clock"
        case .projModifiedDesc:
            return "document.badge.clock"
        }
    }
    
    public var selectedIcon: String {
        switch self {
        case .taskCreationDesc:
            return "calendar.badge.clock"
        case .projModifiedDesc:
            return "document.badge.clock.fill"
        }
    }
    
    public var label: String {
        switch self {
        case .taskCreationDesc:
            return "Task Creation"
        case .projModifiedDesc:
            return "Proj Modified"
        }
    }
    
    public var description: String {
        switch self {
        case .taskCreationDesc:
            return "Sort by task creation time"
        case .projModifiedDesc:
            return "Sort by project modification time"
        }
    }
}

public class TaskSortOrder: ObservableObject {
    public static let shared = TaskSortOrder()
    
    // App Group identifier for sharing with widgets
    private let groupID = "group.us.kothreat.NavTemplate"
    private let sortOrderKey = "TaskSortOrder"
    
    @Published public private(set) var currentOrder: TaskSortOrderType
    
    private var groupDefaults: UserDefaults? {
        UserDefaults(suiteName: groupID)
    }
    
    private init() {
        // Initialize currentOrder from UserDefaults or use default
        if let orderString = UserDefaults(suiteName: groupID)?.string(forKey: sortOrderKey),
           let order = TaskSortOrderType(rawValue: orderString) {
            self.currentOrder = order
        } else {
            self.currentOrder = .taskCreationDesc
            UserDefaults(suiteName: groupID)?.set(TaskSortOrderType.taskCreationDesc.rawValue, forKey: sortOrderKey)
        }
    }
    
    public func updateOrder(_ newOrder: TaskSortOrderType) {
        // Skip if order hasn't changed
        guard currentOrder != newOrder else { return }
        
        currentOrder = newOrder
        groupDefaults?.set(currentOrder.rawValue, forKey: sortOrderKey)
        
        // Post notification with the new order
        NotificationCenter.default.post(
            name: .taskSortOrderDidChange,
            object: nil,
            userInfo: ["sortOrder": currentOrder]
        )
    }
}

public extension Notification.Name {
    static let taskSortOrderDidChange = Notification.Name("taskSortOrderDidChange")
} 