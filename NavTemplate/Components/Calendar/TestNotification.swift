import SwiftUI
import UserNotifications

class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
}

struct TestNotification: View {
    @State private var isAuthorized = false
    @State private var showingPermissionAlert = false
    private let notificationDelegate = NotificationDelegate()
    
    var body: some View {
        Button(action: {
            scheduleTestNotification()
        }) {
            HStack {
                Image(systemName: "bell.badge")
                Text("Test Reminder (5s)")
            }
            .foregroundColor(.white)
            .padding()
            .background(Color("Accent"))
            .cornerRadius(10)
        }
        .alert("Enable Notifications", isPresented: $showingPermissionAlert) {
            Button("Settings", role: .none) {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Notifications are required for reminders. You can enable them in Settings.")
        }
        .task {
            // Set delegate when view appears
            let center = UNUserNotificationCenter.current()
            center.delegate = notificationDelegate
            
            // Check authorization status
            let settings = await center.notificationSettings()
            isAuthorized = settings.authorizationStatus == .authorized
        }
    }
    
    private func scheduleTestNotification() {
        Task {
            let center = UNUserNotificationCenter.current()
            
            if !isAuthorized {
                let granted = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
                print("Authorization request result: \(granted ?? false)")
                if granted != true {
                    showingPermissionAlert = true
                    return
                }
                isAuthorized = true
            }
            
            // Create a simple test notification
            let content = UNMutableNotificationContent()
            content.title = "Test Notification"
            content.body = "This is a test notification"
            content.sound = .default
            
            // Schedule for 5 seconds from now
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
            
            let request = UNNotificationRequest(
                identifier: UUID().uuidString,
                content: content,
                trigger: trigger
            )
            
            do {
                try await center.add(request)
                print("Test notification scheduled for 5 seconds from now")
                
                // List pending notifications
                let pending = await center.pendingNotificationRequests()
                print("Pending notifications: \(pending.count)")
                for req in pending {
                    if let trigger = req.trigger as? UNTimeIntervalNotificationTrigger {
                        print("- Notification will fire in \(trigger.timeInterval) seconds")
                    }
                }
            } catch {
                print("Failed to schedule test notification: \(error)")
            }
        }
    }
} 