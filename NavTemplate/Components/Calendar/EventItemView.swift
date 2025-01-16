import SwiftUI
import NavTemplateShared

public struct EventItemView: View {
    let event: CalendarEvent
    let onEventTap: (CalendarEvent) -> Void
    
    public init(event: CalendarEvent, onEventTap: @escaping (CalendarEvent) -> Void) {
        self.event = event
        self.onEventTap = onEventTap
    }
    
    private var timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()
    
    public var body: some View {
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
                .frame(maxWidth: .infinity)
                
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
        .onTapGesture {
            onEventTap(event)
        }
    }
} 