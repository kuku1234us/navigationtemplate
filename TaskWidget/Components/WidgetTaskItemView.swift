import SwiftUI
import NavTemplateShared

struct WidgetTaskItemView: View {
    let task: WidgetTaskItem
    @State private var currentStatus: String
    
    init(task: WidgetTaskItem) {
        self.task = task
        self._currentStatus = State(initialValue: task.status)
    }
    
    private var statusIcon: String {
        switch currentStatus {
        case TaskStatus.completed.rawValue: return TaskStatus.completed.icon
        case TaskStatus.inProgress.rawValue: return TaskStatus.inProgress.icon
        default: return TaskStatus.notStarted.icon
        }
    }
    
    private var priorityColor: Color {
        switch task.priority {
        case TaskPriority.urgent.rawValue: return TaskPriority.urgent.color
        case TaskPriority.high.rawValue: return TaskPriority.high.color
        case TaskPriority.normal.rawValue: return TaskPriority.normal.color
        default: return TaskPriority.low.color
        }
    }
    
    var body: some View {
        HStack(spacing: 5) {
            // Status icon with priority color
            Button(intent: ToggleTaskIntent(
                taskId: task.taskId,
                newStatus: TaskStatus(rawValue: currentStatus)?.next().rawValue ?? TaskStatus.notStarted.rawValue
            )) {
                Image(systemName: statusIcon)
                    .font(.footnote)
                    .foregroundStyle(priorityColor)
            }
            .buttonStyle(.plain)
            
            // Project icon from ImageCache
            if let uiImage = ImageCache.shared.getImageFromDefaults(folder: "projecticon", key: task.iconImageName) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 12, height: 12)
                    .foregroundStyle(Color("MySecondary"))
            }
            
            // Task name with truncation
            Text(task.name)
                .font(.footnote)
                .foregroundStyle(Color("MySecondary"))
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .padding(.horizontal, 6)
    }
} 
