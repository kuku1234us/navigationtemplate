import SwiftUI

struct ReminderListView: View {
    @Binding var selectedReminders: Set<Int>
    @Binding var showReminderPicker: Bool
    var selectedSound: String
    
    // Make these static so they can be used by EventEditor
    static let reminderOptions = [
        0,      // At time of event
        5,      // 5 minutes
        15,     // 15 minutes
        30,     // 30 minutes
        60,     // 1 hour
        120,    // 2 hours
        1440,   // 1 day
        2880,   // 2 days
        10080   // 1 week
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
                    ForEach(Array(selectedReminders).sorted(), id: \.self) { minutes in
                        ReminderBadge(minutes: minutes) {
                            selectedReminders.remove(minutes)
                        }
                    }
                }
                .padding(.horizontal, 0)
            }
            .frame(height: 32)
        }
    }
} 