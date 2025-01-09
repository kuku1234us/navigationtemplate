// ./NavTemplateShared/Models/DailyModel.swift

import SwiftUI
import Combine
import AppIntents
import WidgetKit

@available(iOS 16.0, *)
public enum ActivityType: String, CaseIterable, AppEnum, Codable {
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

public struct ActivityItem: Identifiable, Codable {
    public let id: UUID
    public let activityType: ActivityType
    public let activityTime: Date
    
    public init(type: ActivityType, time: Date = Date()) {
        self.id = UUID()
        self.activityType = type
        self.activityTime = time
    }
}

public class ActivityStack: ObservableObject {
    @Published public private(set) var items: [ActivityItem] = []
    private var isLoading = false
    private let defaults = UserDefaults(suiteName: "group.us.kothreat.NavTemplate")     
    
    /// Initializes ActivityStack and sets up UserDefaults observation
    public init() {
        setupDefaultsObserver()
    }
    
    /// Sets up observer for UserDefaults changes to detect widget updates
    /// Processes pending activities when they exist
    private func setupDefaultsObserver() {
        NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: defaults,
            queue: .main
        ) { [weak self] _ in
            if let self = self,
               let pendingData = self.defaults?.data(forKey: "PendingActivities"),
               !pendingData.isEmpty {
                self.processPendingActivities()
            }
        }
    }
    
    /// Updates LastKnownActivities in UserDefaults with latest timestamps from items array
    /// This function assumes that all pending activities have been processed and items[] is sorted
    private func updateLastKnownActivities() {
        // Get current timestamps from UserDefaults
        let currentLastKnown = getLastKnownActivitiesFromDefaults() ?? [:]
        
        // Start with copy of current timestamps
        var newLastKnown = currentLastKnown
        
        // Update timestamps for activities we have in items[]
        for type in ActivityType.allCases {
            if let lastItem = items.last(where: { $0.activityType == type }) {
                newLastKnown[type.rawValue.lowercased()] = Int(lastItem.activityTime.timeIntervalSince1970)
            }
        }
        
        // Compare if update is needed
        if newLastKnown != currentLastKnown {
            defaults?.set(newLastKnown, forKey: "LastKnownActivities")
        }
    }
    
    /// Retrieves the LastKnownActivities dictionary from UserDefaults
    /// Returns a dictionary mapping activity types to their last known timestamps
    private func getLastKnownActivitiesFromDefaults() -> [String: Int]? {
        return defaults?.dictionary(forKey: "LastKnownActivities") as? [String: Int]
    }
    
    /// Loads the most recent activities from the iCloud vault
    /// Used by main app only, updates items array and LastKnownActivities
    public func loadActivitiesFromVault() {
        guard !isLoading else { return }
        isLoading = true
        
        defer {
            isLoading = false
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
        
        do {
            // Load activities from vault
            let activities = try QuarterFileManager.shared.loadLatestActivities(count: 50)
            items = activities
            
            // Process any pending activities from widget
            processPendingActivities()
            
            // Update LastKnownActivities with final state
            updateLastKnownActivities()
            
        } catch {
            Logger.shared.error("Failed to load activities from vault: \(error)")
        }
    }
    
    /// Adds a new activity to the iCloud vault and updates local state
    /// Used by main app only
    public func pushActivityToVault(_ item: ActivityItem) {
        defer {
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
        
        do {
            try QuarterFileManager.shared.appendActivity(item)
            items.append(item)
            updateLastKnownActivities()
        } catch {
            Logger.shared.error("Failed to push activity to vault: \(error)")
        }
    }
    
    /// Loads activities from UserDefaults into items array
    /// Used by widget only, combines LastKnownActivities and PendingActivities
    public func loadActivitiesFromDefaults() {
        // Load LastKnownActivities timestamps
        if let lastKnown = defaults?.dictionary(forKey: "LastKnownActivities") as? [String: Int] {
            // Convert timestamps back to ActivityItems
            var activities: [ActivityItem] = []
            for (typeStr, timestamp) in lastKnown {
                if let type = ActivityType(rawValue: typeStr.capitalized) {
                    activities.append(ActivityItem(
                        type: type,
                        time: Date(timeIntervalSince1970: TimeInterval(timestamp))
                    ))
                }
            }
            self.items = activities.sorted(by: { $0.activityTime < $1.activityTime })
            self.updateLastKnownActivities()  // Update timestamps after loading activities
        }
        
        // Append any pending activities
        if let pendingData = defaults?.data(forKey: "PendingActivities"),
           let pendingActivities = try? JSONDecoder().decode([ActivityItem].self, from: pendingData) {
            self.items.append(contentsOf: pendingActivities)
            self.updateLastKnownActivities()  // Update timestamps again with pending activities
        }
    }
    
    /// Adds activity to PendingActivities queue in UserDefaults
    /// Used by widget only when it cannot directly access iCloud vault
    public func pushActivityToQueue(_ item: ActivityItem) {
        defer {
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
        
        var pendingActivities: [ActivityItem] = []
        if let data = defaults?.data(forKey: "PendingActivities"),
           let existing = try? JSONDecoder().decode([ActivityItem].self, from: data) {
            pendingActivities = existing
        }
        
        pendingActivities.append(item)
        
        if let encoded = try? JSONEncoder().encode(pendingActivities) {
            defaults?.set(encoded, forKey: "PendingActivities")
            items.append(item)
            updateLastKnownActivities()
        }
    }
    
    /// Processes activities in PendingActivities queue
    /// Called when main app detects widget updates via UserDefaults changes
    public func processPendingActivities() {
        // Get pending activities
        guard let data = defaults?.data(forKey: "PendingActivities"),
              let pendingActivities = try? JSONDecoder().decode([ActivityItem].self, from: data) else {
            return
        }
        
        // Process all activities first
        var successfulActivities: [ActivityItem] = []
        for activity in pendingActivities {
            do {
                try QuarterFileManager.shared.appendActivity(activity)
                successfulActivities.append(activity)
            } catch {
                Logger.shared.error("Failed to process pending activity: \(error)")
            }
        }
        
        // Clear pending queue first to avoid recursive calls
        defaults?.removeObject(forKey: "PendingActivities")

        // If we processed any activities successfully
        if !successfulActivities.isEmpty {            
            // Update items array
            items.append(contentsOf: successfulActivities)
            items.sort { $0.activityTime < $1.activityTime }
            
            // Update LastKnownActivities after clearing pending queue
            updateLastKnownActivities()
            
            // Notify UI of changes
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }
    
    /// Returns the most recent sleep or wake activity
    public func getLastConsciousItem() -> ActivityItem? {
        return items.last { item in
            item.activityType == .sleep || item.activityType == .wake
        }
    }
    
    /// Returns the most recent meal activity
    public func getLastMealItem() -> ActivityItem? {
        return items.last { item in
            item.activityType == .meal
        }
    }
    
    /// Returns the most recent exercise activity
    public func getLastExerciseItem() -> ActivityItem? {
        return items.last { item in
            item.activityType == .exercise
        }
    }
    
    /// Calculates time elapsed since the last occurrence of specified activity type
    public func timeSince(_ activityType: ActivityType) -> TimeInterval? {
        let item = items.last { item in
            item.activityType == activityType
        }
        guard let item = item else { return nil }
        return Date().timeIntervalSince(item.activityTime)
    }
    
    /// Returns all activities in chronological order
    public var allItems: [ActivityItem] {
        return items
    }
    
    /// Removes an activity from both iCloud vault and local state
    public func removeActivity(_ item: ActivityItem) {
        defer {
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
        
        do {
            try QuarterFileManager.shared.removeActivity(item)
            items.removeAll { $0.id == item.id }
            updateLastKnownActivities()
        } catch {
            print("ActivityStack: Error removing activity: \(error)")
        }
    }
    
    /// Updates an existing activity with new type and/or time
    /// Updates both iCloud vault and local state
    public func updateActivity(_ originalItem: ActivityItem, withType newType: ActivityType, newTime: Date) {
        guard let index = items.firstIndex(where: { $0.id == originalItem.id }) else {
            print("ActivityStack: Cannot find item to update")
            return
        }
        
        let newItem = ActivityItem(type: newType, time: newTime)
        
        defer {
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
        
        do {
            try QuarterFileManager.shared.updateActivity(originalItem, to: newItem)
            items[index] = newItem
            updateLastKnownActivities()
        } catch {
            print("ActivityStack: Error updating activity: \(error)")
        }
    }
    
    /// Triggers widget timeline regeneration to reflect latest changes
    public func rerenderWidget() {
        // This will trigger a new timeline generation with fresh data
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    /// Notifies main app of widget changes by updating LastKnownActivities
    /// Only updates if changes are detected to avoid unnecessary writes
    public func notifyMainApp() {
        // Update LastKnownActivities only if needed
        updateLastKnownActivities()
    }
} 