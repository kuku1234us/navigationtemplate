import SwiftUI
import NavTemplateShared

struct WidgetTaskItemView: View {
    let name: String
    let status: String
    let priority: String
    let iconImageName: String
    
    private var statusIcon: String {
        switch status {
        case TaskStatus.completed.rawValue: return TaskStatus.completed.icon
        case TaskStatus.inProgress.rawValue: return TaskStatus.inProgress.icon
        default: return TaskStatus.notStarted.icon
        }
    }
    
    private var priorityColor: Color {
        switch priority {
        case TaskPriority.urgent.rawValue: return TaskPriority.urgent.color
        case TaskPriority.high.rawValue: return TaskPriority.high.color
        case TaskPriority.normal.rawValue: return TaskPriority.normal.color
        default: return TaskPriority.low.color
        }
    }
    
    var body: some View {
        HStack(spacing: 5) {
            // Status icon with priority color
            Image(systemName: statusIcon)
                .font(.footnote)
                .foregroundStyle(priorityColor)
            
            // Project icon from ImageCache
            if let uiImage = ImageCache.shared.getImageFromDefaults(key: iconImageName) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 12, height: 12)
                    .foregroundStyle(Color("MySecondary"))
            }
            
            // Task name with truncation
            Text(name)
                .font(.footnote)
                .foregroundStyle(Color("MySecondary"))
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .padding(.horizontal, 6)
        .onAppear {
            // Load the icon image from ImageCache
            print("Task: \(name) Loading icon image for \(iconImageName)")
        }
    }
} 
