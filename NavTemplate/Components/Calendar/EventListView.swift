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
        ScrollView {
            LazyVStack(spacing: 8) {
                if events.isEmpty {
                    Text("No events")
                        .foregroundColor(Color("MyTertiary"))
                        .padding()
                } else {
                    ForEach(events, id: \.eventId) { event in
                        EventItemView(event: event, onEventTap: onEventTap)
                            .id("\(event.eventId)-\(event.projId ?? 0)")
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    deleteEvent(event)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                .tint(.red)
                            }
                    }
                }
            }
            .padding(.horizontal, 0)
            .padding(.bottom, NavigationState.bottomMenuHeight + 20)
        }
    }
} 