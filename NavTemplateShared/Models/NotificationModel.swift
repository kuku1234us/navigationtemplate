import Foundation
import UserNotifications

@MainActor
public class NotificationModel: ObservableObject {
    public static let shared = NotificationModel()
    private let defaults = UserDefaults(suiteName: "group.us.kothreat.NavTemplate")
    private let authStatusKey = "notificationAuthorizationStatus"
    private let notificationDelegate = NotificationDelegate()
    
    @Published public private(set) var isAuthorized = false
    
    private init() {
        // Load saved authorization status
        isAuthorized = defaults?.bool(forKey: authStatusKey) ?? false
        
        // Set delegate for foreground notifications
        UNUserNotificationCenter.current().delegate = notificationDelegate
    }
    
    /// Check current authorization status
    public func checkAuthorizationStatus() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized
        defaults?.set(isAuthorized, forKey: authStatusKey)
    }
    
    /// Request notification permissions from the user
    public func requestAuthorization() async -> Bool {
        do {
            let center = UNUserNotificationCenter.current()
            let options: UNAuthorizationOptions = [.alert, .sound, .badge]
            let granted = try await center.requestAuthorization(options: options)
            isAuthorized = granted
            defaults?.set(granted, forKey: authStatusKey)
            return granted
        } catch {
            Logger.shared.error("[E025] Failed to request notification authorization: \(error)")
            return false
        }
    }
    
    /// Schedule notifications for an event's reminders
    public func scheduleEventReminders(for event: CalendarEvent) async {
        let center = UNUserNotificationCenter.current()
        
        // First remove any existing notifications for this event
        await removeEventReminders(for: event.eventId)
        
        // Create new notifications for each reminder time
        for minutesBefore in event.reminders {
            let triggerDate = Date(timeIntervalSince1970: TimeInterval(event.startTime))
                .addingTimeInterval(TimeInterval(-minutesBefore * 60))
            
            // Don't schedule if trigger time is in the past
            guard triggerDate > Date() else {
                Logger.shared.error("Skipping notification - trigger date is in past: \(triggerDate)")
                continue
            }
            
            let content = UNMutableNotificationContent()
            content.title = event.eventTitle
            content.body = createReminderBody(event: event, minutesBefore: minutesBefore)
            content.sound = .default
            
            // For testing purposes, if the trigger is within 60 seconds, use a time interval trigger
            let timeUntilTrigger = triggerDate.timeIntervalSince(Date())
            let trigger: UNNotificationTrigger
            
            if timeUntilTrigger <= 60 {
                trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeUntilTrigger, repeats: false)
                Logger.shared.debug("Using time interval trigger for: \(timeUntilTrigger) seconds")
            } else {
                let components = Calendar.current.dateComponents(
                    [.year, .month, .day, .hour, .minute, .second],
                    from: triggerDate
                )
                trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                Logger.shared.debug("Using calendar trigger for: \(triggerDate)")
            }
            
            let identifier = notificationIdentifier(eventId: event.eventId, minutesBefore: minutesBefore)
            let request = UNNotificationRequest(
                identifier: identifier,
                content: content,
                trigger: trigger
            )
            
            do {
                try await center.add(request)
                Logger.shared.debug("Successfully scheduled notification for \(triggerDate)")
                
                // Debug: List all pending notifications
                let pending = await center.pendingNotificationRequests()
                Logger.shared.debug("Pending notifications: \(pending.count)")
                for req in pending {
                    if let trigger = req.trigger as? UNCalendarNotificationTrigger {
                        Logger.shared.debug("- \(req.identifier) scheduled for: \(trigger.nextTriggerDate() ?? Date())")
                    } else if let trigger = req.trigger as? UNTimeIntervalNotificationTrigger {
                        Logger.shared.debug("- \(req.identifier) in \(trigger.timeInterval) seconds")
                    }
                }
            } catch {
                Logger.shared.error("Failed to schedule notification: \(error)")
            }
        }
    }
    
    /// Remove all notifications for a specific event
    public func removeEventReminders(for eventId: Int64) async {
        let center = UNUserNotificationCenter.current()
        let identifiers = await center.pendingNotificationRequests()
            .filter { $0.identifier.starts(with: "event_\(eventId)_") }
            .map { $0.identifier }
        
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }
    
    /// Create a unique identifier for each notification
    private func notificationIdentifier(eventId: Int64, minutesBefore: Int) -> String {
        return "event_\(eventId)_\(minutesBefore)"
    }
    
    /// Create the notification message
    private func createReminderBody(event: CalendarEvent, minutesBefore: Int) -> String {
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        let startTime = timeFormatter.string(from: Date(timeIntervalSince1970: TimeInterval(event.startTime)))
        
        var body = "Starts at \(startTime)"
        if let location = event.location {
            body += " at \(location)"
        }
        return body
    }
}

private class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
} 