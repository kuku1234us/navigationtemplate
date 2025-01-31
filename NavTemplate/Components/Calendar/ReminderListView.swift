import SwiftUI
import NavTemplateShared

struct ReminderListView: View {
    @Binding var selectedReminders: Set<ReminderType>
    @Binding var showReminderPicker: Bool
    
    // Change to Int array for time-only options
    static let reminderOptions: [Int] = [
        0,      // At time of event
        5,      // 5 minutes before
        15,     // 15 minutes before
        30,     // 30 minutes before
        60,     // 1 hour before
        120,    // 2 hours before
        1440,   // 1 day before
        2880,    // 2 days before
        10080    // 1 week before
    ]
    
    static func formatReminderOption(_ minutes: Int) -> String {
        if minutes == 0 {
            return "@Event"
        } else if minutes >= 1440 { // 24 hours
            let days = minutes / 1440
            return "\(days) day\(days > 1 ? "s" : "") before"
        } else if minutes >= 60 {
            let hours = minutes / 60
            return "\(hours) hour\(hours > 1 ? "s" : "") before"
        } else {
            return "\(minutes) minute\(minutes > 1 ? "s" : "") before"
        }
    }
    
    var body: some View {
        // Selected reminders (only show if there are any)
        if !selectedReminders.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(selectedReminders).sorted(by: { $0.minutes < $1.minutes }), id: \.minutes) { reminder in
                        ReminderBadge(reminder: reminder, onRemove: {
                            selectedReminders.remove(reminder)
                        })
                    }
                }
                .padding(.horizontal, 0)
            }
            .frame(height: 32)
        }
    }
}

