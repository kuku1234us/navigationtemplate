import Foundation
import UserNotifications
import AudioToolbox

@MainActor
public class NotificationModel: ObservableObject {
    public static let shared = NotificationModel()
    private let defaults = UserDefaults(suiteName: "group.us.kothreat.NavTemplate")
    private let authStatusKey = "notificationAuthorizationStatus"
    private let notificationDelegate = NotificationDelegate()
    private let notificationSoundName = "pending-notification"
    
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
            
            guard triggerDate > Date() else { continue }
            
            let content = UNMutableNotificationContent()
            content.title = event.eventTitle
            content.body = createReminderBody(event: event, minutesBefore: minutesBefore)
            
            // Set the custom notification sound
            let soundName = UNNotificationSoundName(rawValue: "\(notificationSoundName).aiff")
            content.sound = UNNotificationSound(named: soundName)
            
            let components = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute, .second],
                from: triggerDate
            )
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            
            let identifier = notificationIdentifier(eventId: event.eventId, minutesBefore: minutesBefore)
            let request = UNNotificationRequest(
                identifier: identifier,
                content: content,
                trigger: trigger
            )
            
            do {
                try await center.add(request)
            } catch {
                Logger.shared.error("[E026] Failed to schedule notification: \(error)")
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
    
    /// Test play the notification sound
    public func playNotificationSound() {
        // Look for sound file in NavTemplateShared bundle
        if let soundURL = Bundle(for: NotificationModel.self).url(forResource: notificationSoundName, withExtension: "aiff") {
            var soundID: SystemSoundID = 0
            AudioServicesCreateSystemSoundID(soundURL as CFURL, &soundID)
            AudioServicesPlaySystemSound(soundID)
            
            // Clean up after playing
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                AudioServicesDisposeSystemSoundID(soundID)
            }
        } else {
            Logger.shared.error("[E028] Failed to find notification sound file in NavTemplateShared bundle")
        }
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