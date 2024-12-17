import SwiftUI
import Combine
import AppIntents
import WidgetKit

@available(iOS 16.0, *)
public enum ActivityType: String, CaseIterable, AppEnum {
    case sleep = "Sleep"
    case wake = "Wake"
    case meal = "Meal"
    case exercise = "Exercise"
    
    public var unfilledIcon: String {
        switch self {
        case .sleep: return "bed.double"
        case .wake: return "alarm"
        case .meal: return "fork.knife"
        case .exercise: return "figure.run"
        }
    }
    
    public var filledIcon: String {
        switch self {
        case .sleep: return "bed.double.fill"
        case .wake: return "alarm.fill"
        case .meal: return "fork.knife.circle.fill"
        case .exercise: return "figure.run.circle.fill"
        }
    }
    
    public static var typeDisplayRepresentation: TypeDisplayRepresentation = "Activity Type"
    
    public static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .sleep: .init(
            title: LocalizedStringResource(stringLiteral: "Sleep"),
            subtitle: LocalizedStringResource(stringLiteral: "Add Sleep activity")
        ),
        .wake: .init(
            title: LocalizedStringResource(stringLiteral: "Wake"),
            subtitle: LocalizedStringResource(stringLiteral: "Add Wake activity")
        ),
        .meal: .init(
            title: LocalizedStringResource(stringLiteral: "Meal"),
            subtitle: LocalizedStringResource(stringLiteral: "Add Meal activity")
        ),
        .exercise: .init(
            title: LocalizedStringResource(stringLiteral: "Exercise"),
            subtitle: LocalizedStringResource(stringLiteral: "Add Exercise activity")
        )
    ]
    
    public var displayRepresentation: DisplayRepresentation {
        Self.caseDisplayRepresentations[self] ?? .init(
            title: LocalizedStringResource(stringLiteral: self.rawValue),
            subtitle: LocalizedStringResource(stringLiteral: "Add \(self.rawValue) activity")
        )
    }
    
    public var identifier: String {
        return self.rawValue.lowercased()
    }
    
    public var displayValue: String {
        return self.rawValue
    }
}

public struct Activity: Hashable {
    public let type: ActivityType
    
    public init(type: ActivityType) {
        self.type = type
    }
    
    public var name: String { type.rawValue }
    public var unfilledIcon: String { type.unfilledIcon }
    public var filledIcon: String { type.filledIcon }
}

public struct ActivityItem: Identifiable {
    public let id = UUID()
    public let activityType: ActivityType
    public let activityTime: Date
    
    public init(type: ActivityType, time: Date = Date()) {
        self.activityType = type
        self.activityTime = time
    }
}

public class ActivityStack: ObservableObject {
    @Published public private(set) var items: [ActivityItem] = []
    private var isLoading = false
    private let defaults = UserDefaults(suiteName: "group.us.kothreat.NavTemplate")
    private var lastUpdateTime: TimeInterval = 0
    
    public init() {
        setupObserver()
        setupDefaultsObserver()
    }
    
    private func setupDefaultsObserver() {
        NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: defaults,
            queue: .main
        ) { [weak self] _ in
            if let updateTime = self?.defaults?.double(forKey: "LastActivityUpdate"),
               updateTime > self?.lastUpdateTime ?? 0 {
                self?.lastUpdateTime = updateTime
                self?.loadActivities()
            }
        }
    }
    
    public func loadActivities(isWidget: Bool = false) {
        guard !isLoading else { return }
        isLoading = true
        
        do {
            let activities = try QuarterFileManager.shared.loadLatestActivities(count: 50)
            
            if isWidget {
                // In widget context, update directly
                self.items = activities
                self.isLoading = false
            } else {
                // In main app context, use main queue for UI updates
                DispatchQueue.main.async {
                    self.items = activities
                    self.isLoading = false
                }
            }
        } catch {
            print("ActivityStack: Error loading activities: \(error)")
            isLoading = false
        }
    }
    
    public func pushActivity(_ item: ActivityItem) {
        do {
            try QuarterFileManager.shared.appendActivity(item)
            DispatchQueue.main.async {
                self.items.append(item)
            }
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
        return items.last { item in
            item.activityType == .sleep || item.activityType == .wake
        }
    }
    
    public func getLastMealItem() -> ActivityItem? {
        return items.last { item in
            item.activityType == .meal
        }
    }
    
    public func getLastExerciseItem() -> ActivityItem? {
        return items.last { item in
            item.activityType == .exercise
        }
    }
    
    public func timeSince(_ activityType: ActivityType) -> TimeInterval? {
        let item = items.last { item in
            item.activityType == activityType
        }
        guard let item = item else { return nil }
        return Date().timeIntervalSince(item.activityTime)
    }
    
    public func timeInCurrentConsciousState() -> TimeInterval? {
        guard let lastConscious = getLastConsciousItem() else { return nil }
        return Date().timeIntervalSince(lastConscious.activityTime)
    }
    
    public var allItems: [ActivityItem] {
        return items
    }
    
    public func removeActivity(_ item: ActivityItem) {
        do {
            try QuarterFileManager.shared.removeActivity(item)
            DispatchQueue.main.async {
                self.items.removeAll { $0.id == item.id }
            }
        } catch {
            print("ActivityStack: Error removing activity: \(error)")
        }
    }
    
    public func updateActivity(_ originalItem: ActivityItem, withType newType: ActivityType, newTime: Date) {
        guard let index = items.firstIndex(where: { $0.id == originalItem.id }) else {
            print("ActivityStack: Cannot find item to update")
            return
        }
        
        let newItem = ActivityItem(type: newType, time: newTime)
        
        do {
            try QuarterFileManager.shared.updateActivity(originalItem, to: newItem)
            DispatchQueue.main.async {
                self.items[index] = newItem
            }
        } catch {
            print("ActivityStack: Error updating activity: \(error)")
        }
    }
    
    public func rerenderWidget() {
        // This will trigger a new timeline generation with fresh data
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    public func notifyMainApp() {
        defaults?.set(Date().timeIntervalSince1970, forKey: "LastActivityUpdate")
        defaults?.synchronize()
    }
    
    // Add observer setup
    private func setupObserver() {
        NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: defaults,
            queue: .main
        ) { [weak self] _ in
            self?.checkForUpdates()
        }
    }
    
    private func checkForUpdates() {
        // Reload activities if timestamp changed
        if defaults?.object(forKey: "LastActivityUpdate") != nil {
            self.loadActivities()
        }
    }
} 