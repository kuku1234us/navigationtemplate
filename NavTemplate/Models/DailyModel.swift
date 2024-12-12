import SwiftUI

public enum ActivityType: String, CaseIterable {
    case sleep = "Sleep"
    case wake = "Wake"
    case meal = "Meal"
    case exercise = "Exercise"
    
    var unfilledIcon: String {
        switch self {
        case .sleep:
            return "bed.double"
        case .wake:
            return "alarm"
        case .meal:
            return "fork.knife"
        case .exercise:
            return "figure.run"
        }
    }
    
    var filledIcon: String {
        switch self {
        case .sleep:
            return "bed.double.fill"
        case .wake:
            return "alarm.fill"
        case .meal:
            return "fork.knife.circle.fill"
        case .exercise:
            return "figure.run.circle.fill"
        }
    }
}

public struct Activity: Hashable {
    let type: ActivityType
    
    public init(type: ActivityType) {
        self.type = type
    }
    
    var name: String { type.rawValue }
    var unfilledIcon: String { type.unfilledIcon }
    var filledIcon: String { type.filledIcon }
}

public struct ActivityItem: Identifiable {
    public let id = UUID()
    let activityType: ActivityType
    let activityTime: Date
    
    init(type: ActivityType, time: Date = Date()) {
        self.activityType = type
        self.activityTime = time
    }
}

public class ActivityStack: ObservableObject {
    @Published private var items: [ActivityItem] = []
    private var isLoading = false  // Add loading state
    
    public func loadActivities() {
        // Prevent multiple concurrent loads
        guard !isLoading else {
            return
        }
        
        isLoading = true
        
        do {
            let activities = try QuarterFileManager.shared.loadLatestActivities(count: 50)
            
            // Update on main thread since we're using @Published
            DispatchQueue.main.async {
                self.items = activities
                self.isLoading = false
            }
        } catch QuarterFileManager.QuarterFileError.noVaultAccess {
            print("ActivityStack: No vault access available")
            isLoading = false
        } catch {
            print("ActivityStack: Error loading activities: \(error)")
            isLoading = false
        }
    }
    
    public func pushActivity(_ item: ActivityItem) {
        do {
            try QuarterFileManager.shared.appendActivity(item)
            
            // Only update items if file write was successful
            DispatchQueue.main.async {
                self.items.append(item)
            }
        } catch QuarterFileManager.QuarterFileError.noVaultAccess {
            print("ActivityStack: Cannot push activity - no vault access")
        } catch {
            print("ActivityStack: Error pushing activity: \(error)")
        }
    }
    
    public func popActivity() -> ActivityItem? {
        guard !items.isEmpty else { return nil }
        return items.removeLast()
    }
    
    public func getTopActivity() -> ActivityItem? {
        return items.last
    }
    
    public func getLastConsciousItem() -> ActivityItem? {
        let item = items.last { item in
            item.activityType == .sleep || item.activityType == .wake
        }
        return item
    }
    
    public func getLastMealItem() -> ActivityItem? {
        let item = items.last { item in
            item.activityType == .meal
        }
        return item
    }
    
    public func getLastExerciseItem() -> ActivityItem? {
        return items.last { item in
            item.activityType == .exercise
        }
    }
    
    // Helper to get time interval since a specific activity
    public func timeSince(_ activityType: ActivityType) -> TimeInterval? {
        let item = items.last { item in
            item.activityType == activityType
        }
        guard let item = item else { return nil }
        return Date().timeIntervalSince(item.activityTime)
    }
    
    // Helper to get time in current conscious state
    public func timeInCurrentConsciousState() -> TimeInterval? {
        guard let lastConscious = getLastConsciousItem() else { return nil }
        return Date().timeIntervalSince(lastConscious.activityTime)
    }
    
    // Get all items for display
    public var allItems: [ActivityItem] {
        return items
    }
} 