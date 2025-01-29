// ./NavTemplate/Components/Calendar/EventListView.swift

import SwiftUI
import NavTemplateShared

struct EventListView: View {

    let events: [CalendarEvent]
    let onEventTap: (CalendarEvent) -> Void
    @StateObject private var calendarModel = CalendarModel.shared
    @StateObject private var projectModel = ProjectModel.shared
    
    @State private var activeEventId: Int64?
    @State private var offset: CGFloat = 0
    private let deleteButtonWidth: CGFloat = 80
    private let minDragDistance: CGFloat = 5
    
    private struct DeleteEventButton: View {
        let width: CGFloat
        let event: CalendarEvent
        @StateObject private var calendarModel = CalendarModel.shared
        
        var body: some View {
            HStack {
                Spacer()
                Button {
                    Task {
                        do {
                            try await calendarModel.deleteEvent(withId: event.eventId)
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        } catch {
                            Logger.shared.error("[E024] Failed to delete event: \(error)")
                        }
                    }
                } label: {
                    Image(systemName: "trash")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: width)
                        .frame(maxHeight: .infinity)
                        .background(Color.red.opacity(0.5))
                }
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
                    ZStack {
                        // Delete button
                        DeleteEventButton(
                            width: deleteButtonWidth, 
                            event: event
                        )
                        .offset(x: event.eventId == activeEventId ? 
                            offset + deleteButtonWidth : // Active: Move with drag
                            deleteButtonWidth           // Inactive: Stay hidden off-screen
                        )
                        
                        // Event content
                        EventItemView(event: event, onEventTap: onEventTap)
                            .offset(x: event.eventId == activeEventId ? offset : 0)
                    }
                    .clipped()
                    .simultaneousGesture(
                        DragGesture(minimumDistance: minDragDistance)
                            .onChanged { value in
                                if activeEventId != event.eventId {
                                    activeEventId = event.eventId
                                    offset = 0
                                }
                                
                                let newOffset = min(0, max(-deleteButtonWidth, value.translation.width))
                                withAnimation(.interactiveSpring()) {
                                    offset = newOffset
                                }
                            }
                            .onEnded { value in
                                let velocity = value.predictedEndLocation.x - value.location.x
                                let shouldSnap = abs(offset) > deleteButtonWidth/2 || velocity < -100
                                
                                withAnimation(.spring(
                                    response: 0.3,
                                    dampingFraction: 0.8,
                                    blendDuration: 0
                                )) {
                                    offset = shouldSnap ? -deleteButtonWidth : 0
                                }
                                
                                if !shouldSnap {
                                    activeEventId = nil
                                }
                            }
                    )
                }
                .padding(.bottom, NavigationState.bottomMenuHeight + 20)
            }
            .simultaneousGesture(
                DragGesture()
                    .onChanged { _ in
                        if activeEventId != nil {
                            withAnimation(.spring()) {
                                offset = 0
                                activeEventId = nil
                            }
                        }
                    }
            )
        }
    }
} 