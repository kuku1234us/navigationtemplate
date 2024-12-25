import SwiftUI
import NavTemplateShared

struct PriorityToggle: View {
    let priority: TaskPriority
    @Binding var isSelected: Bool
    
    var body: some View {
        Button {
            isSelected.toggle()
            UIImpactFeedbackGenerator.impact(.light)
        } label: {
            ZStack {
                // Clear background circle
                Circle()
                    .stroke(Color("MyTertiary").opacity(0.3), lineWidth: 1)
                    .frame(width: 24, height: 24)
                
                // Priority color dot
                Circle()
                    .fill(priority.color.opacity(isSelected ? 1.0 : 0.3))
                    .frame(width: 8, height: 8)
                    .scaleEffect(isSelected ? 2.0 : 1.0)
                    .animation(.spring(duration: 0.3), value: isSelected)
            }
        }
    }
}

struct StatusToggle: View {
    let status: TaskStatus
    @Binding var isSelected: Bool
    
    var iconName: String {
        switch status {
        case .notStarted:
            return isSelected ? "square.fill" : "square"
        case .inProgress:
            return isSelected ? "square.lefthalf.filled" : "square.lefthalf.filled"
        case .completed:
            return isSelected ? "checkmark.square.fill" : "checkmark.square"
        @unknown default:
            return "square"
        }
    }
    
    var body: some View {
        Button {
            isSelected.toggle()
            UIImpactFeedbackGenerator.impact(.light)
        } label: {
            Image(systemName: iconName)
                .foregroundColor(isSelected ? Color("Accent") : Color("MySecondary"))
                .opacity(isSelected ? 1.0 : 0.3)
                .scaleEffect(isSelected ? 1.2 : 1.0)
                .animation(.spring(duration: 0.3), value: isSelected)
        }
    }
}

struct TaskFilterMenu: View {
    @StateObject private var taskModel = TaskModel.shared
    
    var body: some View {
        HStack(spacing: 16) {
            // Priority toggles
            HStack(spacing: 12) {
                ForEach([TaskPriority.urgent, .high, .normal, .low], id: \.self) { priority in
                    PriorityToggle(
                        priority: priority,
                        isSelected: .init(
                            get: { taskModel.filterToggles.priorities.contains(priority) },
                            set: { isSelected in
                                var priorities = taskModel.filterToggles.priorities
                                if isSelected {
                                    priorities.insert(priority)
                                } else {
                                    priorities.remove(priority)
                                }
                                taskModel.updateFilterToggles(priorities: priorities)
                            }
                        )
                    )
                }
            }
            
            // Vertical divider
            Rectangle()
                .fill(Color("MyTertiary").opacity(0.3))
                .frame(width: 1, height: 20)
            
            // Status toggles
            HStack(spacing: 12) {
                ForEach([TaskStatus.notStarted, .inProgress, .completed], id: \.self) { status in
                    StatusToggle(
                        status: status,
                        isSelected: .init(
                            get: { taskModel.filterToggles.statuses.contains(status) },
                            set: { isSelected in
                                var statuses = taskModel.filterToggles.statuses
                                if isSelected {
                                    statuses.insert(status)
                                } else {
                                    statuses.remove(status)
                                }
                                taskModel.updateFilterToggles(statuses: statuses)
                            }
                        )
                    )
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color("SideSheetBg").opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .padding(.horizontal)
        .padding(.bottom, NavigationState.bottomMenuHeight-(UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 0))
    }
} 