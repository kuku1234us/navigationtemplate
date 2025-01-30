import SwiftUI
import NavTemplateShared

struct ReminderListView: View {
    @Binding var selectedReminders: Set<ReminderType>
    @Binding var showReminderPicker: Bool
    
    // Make these static so they can be used by EventEditor
    static let reminderOptions = [
        ReminderType(minutes: 0),      // At time of event
        ReminderType(minutes: 5),      // 5 minutes
        ReminderType(minutes: 15),     // 15 minutes
        ReminderType(minutes: 30),     // 30 minutes
        ReminderType(minutes: 60),     // 1 hour
        ReminderType(minutes: 120),    // 2 hours
        ReminderType(minutes: 1440),   // 1 day
        ReminderType(minutes: 2880),   // 2 days
        ReminderType(minutes: 10080)   // 1 week
    ]
    
    static func formatReminderOption(_ reminder: ReminderType) -> String {
        if reminder.minutes == 0 {
            return "@Event"
        } else if reminder.minutes >= 1440 { // 24 hours
            let days = reminder.minutes / 1440
            return "\(days) day\(days > 1 ? "s" : "") before"
        } else if reminder.minutes >= 60 {
            let hours = reminder.minutes / 60
            return "\(hours) hour\(hours > 1 ? "s" : "") before"
        } else {
            return "\(reminder.minutes) minute\(reminder.minutes > 1 ? "s" : "") before"
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

