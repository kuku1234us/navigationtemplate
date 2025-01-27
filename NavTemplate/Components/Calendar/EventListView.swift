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
            VStack {
                Spacer()
                ZStack{

                    Text("No events")
                        .font(.system(size: 40))
                        .fontWeight(.black)
                        .foregroundColor(Color("MyTertiary").opacity(0.3))
                        .padding()
                }
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.bottom, NavigationState.bottomMenuHeight + 100)
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