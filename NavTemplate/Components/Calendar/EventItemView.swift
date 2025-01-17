import SwiftUI
import NavTemplateShared

public struct EventItemView: View {
    let event: CalendarEvent
    let onEventTap: (CalendarEvent) -> Void
    @State private var offset: CGFloat = 0
    
    private let minDragDistance: CGFloat = 5
    private let deleteButtonWidth: CGFloat = 80
    
    public init(event: CalendarEvent, onEventTap: @escaping (CalendarEvent) -> Void) {
        self.event = event
        self.onEventTap = onEventTap
    }
    
    private var timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()
    
    private struct DeleteEventButton: View {
        let width: CGFloat
        let offset: CGFloat
        let event: CalendarEvent
        
        @StateObject private var calendarModel = CalendarModel.shared
        
        var body: some View {
            HStack {
                Spacer()
                HStack(alignment: .center) {
                    Spacer()
                    Button {
                        Task {
                            do {
                                try await calendarModel.deleteEvent(withId: event.eventId)
                                // Haptic feedback for successful deletion
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            } catch {
                                Logger.shared.error("[E024] Failed to delete event: \(error)")
                            }
                        }
                    } label: {
                        Image(systemName: "trash")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    Spacer()                    
                }
                .frame(maxHeight: .infinity)
                .frame(width: width)
                .background(Color.red.opacity(0.5))
                .offset(x: offset + width)
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    public var body: some View {
        ZStack {
            // Delete button background
            DeleteEventButton(
                width: deleteButtonWidth, 
                offset: offset,
                event: event
            )
            
            // Main content
            HStack(spacing: 5) {
                // Time column with icon
                HStack(spacing: 10) {
                    CalendarBadge(date: Date(timeIntervalSince1970: TimeInterval(event.startTime)))
                    
                    VStack(alignment: .trailing) {
                        Text(timeFormatter.string(from: Date(timeIntervalSince1970: TimeInterval(event.startTime))))
                            .font(.subheadline)
                            .foregroundColor(Color("MySecondary"))
                        Text(timeFormatter.string(from: Date(timeIntervalSince1970: TimeInterval(event.endTime))))
                            .font(.caption)
                            .foregroundColor(Color("MyTertiary"))
                    }
                }
                .padding(.horizontal, 10)
                
                // Vertical line with dot
                VStack(spacing: 0) {
                    Circle()
                        .fill(Color("Accent"))
                        .frame(width: 8, height: 8)
                    Rectangle()
                        .fill(Color("MyTertiary").opacity(0.3))
                        .frame(width: 2)
                }
                
                // Event details
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        // Project icon
                        if let projId = event.projId,
                           let project = ProjectModel.shared.getProject(withId: projId) {
                            if let iconFilename = project.icon {
                                CachedAsyncImage(
                                    source: .local(iconFilename),
                                    width: 16,
                                    height: 16
                                )
                            } else {
                                CalendarIcon()
                                    .frame(width: 16, height: 16)
                                    .foregroundColor(Color("MySecondary"))
                            }
                        }
                        
                        Text(event.eventTitle)
                            .font(.headline)
                            .foregroundColor(Color("MySecondary"))
                        
                        if let recurrence = event.recurrence {
                            Image(systemName: recurrence == "D" ? "d.circle.fill" :
                                           recurrence == "W" ? "w.circle.fill" :
                                           recurrence == "M" ? "m.circle.fill" :
                                           recurrence == "Y" ? "a.circle.fill" : "")
                                .foregroundColor(Color("Accent").opacity(0.7))
                        }

                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: minDragDistance)
                            .onChanged { value in
                                // Only allow left swipe (negative values) up to delete button width
                                let newOffset = min(0, max(-deleteButtonWidth, value.translation.width))
                                offset = newOffset
                            }
                            .onEnded { value in
                                // Snap to position based on velocity and distance
                                let velocity = value.predictedEndLocation.x - value.location.x
                                let shouldSnap = abs(offset) > deleteButtonWidth/2 || velocity < -100
                                
                                withAnimation(.spring()) {
                                    offset = shouldSnap ? -deleteButtonWidth : 0
                                }
                            }
                    )
                    
                    if let location = event.location {
                        HStack {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundColor(Color("MyTertiary"))
                            Text(location)
                                .font(.caption)
                                .foregroundColor(Color("MyTertiary"))
                        }
                    }
                    
                    if let url = event.url {
                        HStack {
                            Image(systemName: "video.circle.fill")
                                .foregroundColor(Color("MyTertiary"))
                            Text(url)
                                .font(.caption)
                                .foregroundColor(Color("MyTertiary"))
                        }
                    }
                }
                .padding(.leading, 10)
                
                Spacer()
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 0)
            .background(Color("Background").opacity(0.5))
            .cornerRadius(12)
            .offset(x: offset)
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .onTapGesture {
            onEventTap(event)
        }
        .clipped()
    }
} 