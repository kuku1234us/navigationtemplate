import SwiftUI

public enum TaskPriority: String, Hashable {
    case urgent = "Urgent"
    case high = "High"
    case normal = "Normal"
    case low = "Low"
    
    // Add case-insensitive initializer
    public init?(rawValue: String) {
        switch rawValue.lowercased() {
        case "urgent": self = .urgent
        case "high": self = .high
        case "normal": self = .normal
        case "low": self = .low
        default: return nil
        }
    }
    
    public var color: Color {
        switch self {
        case .urgent: return Color("UrgentPriorityColor")
        case .high: return Color("HighPriorityColor")
        case .normal: return Color("NormalPriorityColor")
        case .low: return Color("LowPriorityColor")
        }
    }
    
    // Returns true if self is higher priority than other
    public func isHigherThan(_ other: TaskPriority) -> Bool {
        let priorities: [TaskPriority] = [.urgent, .high, .normal, .low]
        guard let selfIndex = priorities.firstIndex(of: self),
              let otherIndex = priorities.firstIndex(of: other) else {
            return false
        }
        return selfIndex < otherIndex
    }
} 