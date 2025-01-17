import SwiftUI
import NavTemplateShared

struct EventListView: View {
    let events: [CalendarEvent]
    let onEventTap: (CalendarEvent) -> Void
    @StateObject private var calendarModel = CalendarModel.shared
    @StateObject private var projectModel = ProjectModel.shared
    
    private func deleteEvent(_ event: CalendarEvent) {
        Task {
            do {
                // try await calendarModel.deleteEvent(withId: event.eventId)
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            } catch {
                print("Failed to delete event: \(error)")
            }
        }
    }
    
    var body: some View {
        if events.isEmpty {
            Text("No events")
                .foregroundColor(Color("MyTertiary"))
                .padding()
        } else {
            ScrollView {
                ForEach(events, id: \.eventId) { event in
                    EventItemView(event: event, onEventTap: onEventTap)
                }
                .padding(.bottom, NavigationState.bottomMenuHeight + 20)
            }
        }
    }
} 