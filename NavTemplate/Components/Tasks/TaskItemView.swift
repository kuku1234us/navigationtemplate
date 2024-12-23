import SwiftUI
import NavTemplateShared
import CoreHaptics

extension UIImpactFeedbackGenerator {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
}

struct CustomCheckbox: View {
    let taskStatus: TaskStatus
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: taskStatus.icon)
                .symbolRenderingMode(.hierarchical)
                .foregroundColor(taskStatus == .completed ? Color("Accent") : Color("MySecondary"))
                .font(.system(size: 20))
        }
    }
}

struct HapticMenuStyle: MenuStyle {
    func makeBody(configuration: Configuration) -> some View {
        Menu(configuration)
            .simultaneousGesture(
                TapGesture()
                    .onEnded { _ in
                        print("Menu tapped")
                        UIImpactFeedbackGenerator.impact(.light)
                    }
            )
    }
}

struct DeleteTaskButton: View {
    let onDelete: () -> Void
    @State private var showDeletePopover = false
    
    var body: some View {
        Button {
            UIImpactFeedbackGenerator.impact(.light)
            showDeletePopover = true
        } label: {
            Image(systemName: "trash")
                .font(.system(size: 16))
                .foregroundColor(Color("MySecondary"))
        }
        .popover(isPresented: $showDeletePopover) {
            Button(role: .destructive) {
                UIImpactFeedbackGenerator.impact(.light)
                onDelete()
                showDeletePopover = false
            } label: {
                Label("Delete Task", systemImage: "trash")
                    .foregroundColor(.red)
                    .padding(.horizontal, 12)
            }
            .buttonStyle(.borderless)
            .presentationCompactAdaptation(.popover)
            .padding(0)
        }
    }
}

struct TaskItemView: View {
    let task: NavTemplateShared.TaskItem
    let onEdit: () -> Void
    let onDelete: () -> Void
    @State private var taskName: String
    @State private var isChecked: Bool
    @State private var isEditing: Bool = false
    @State private var editorHeight: CGFloat = 30
    @StateObject private var taskModel = TaskModel.shared
    @FocusState private var isEditorFocused: Bool
    
    init(task: NavTemplateShared.TaskItem, 
         onEdit: @escaping () -> Void,
         onDelete: @escaping () -> Void) {
        self.task = task
        self.onEdit = onEdit
        self.onDelete = onDelete
        _taskName = State(initialValue: task.name)
        _isChecked = State(initialValue: task.taskStatus == .completed)
    }
    
    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "N/A" }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    private func priorityColor(_ priority: TaskPriority) -> Color {
        switch priority {
        case .urgent: return Color("UrgentPriorityColor")
        case .high: return Color("HighPriorityColor")
        case .normal: return Color("NormalPriorityColor")
        case .low: return Color("LowPriorityColor")
        @unknown default:
            return Color("NormalPriorityColor")  // Default color for unknown cases
        }
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 5) {
            // 1. Custom Checkbox
            CustomCheckbox(taskStatus: task.taskStatus) {
                // Cycle through statuses: notStarted -> completed -> inProgress -> notStarted
                let newStatus: TaskStatus
                switch task.taskStatus {
                case .notStarted:
                    newStatus = .completed
                case .completed:
                    newStatus = .inProgress
                case .inProgress:
                    newStatus = .notStarted
                }
                taskModel.updateTaskStatus(task, status: newStatus)
            }
            
            // 2. Task details
            VStack(alignment: .leading, spacing: 0) {
                // Task name editor with proper height and alignment
                ZStack(alignment: .topLeading) {
                    // Hidden text for height measurement
                    Text(taskName)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.clear)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.vertical, 4)
                        .background(GeometryReader { geometry in
                            Color.clear.preference(
                                key: ViewHeightKey.self,
                                value: geometry.size.height
                            )
                        })
                    
                    // Actual editor
                    TextEditor(text: $taskName)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color("MyPrimary"))
                        .frame(height: max(editorHeight + 8, 38))
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .disabled(!isEditing)
                        .padding(.leading, -5)
                        .padding(.top, -7)
                        .focused($isEditorFocused)
                        .onChange(of: isEditorFocused) { oldValue, newValue in
                            if !newValue {  // Editor lost focus
                                isEditing = false
                                if task.name != taskName.trimmingCharacters(in: .whitespacesAndNewlines) {
                                    taskModel.updateTaskName(
                                        task,
                                        newName: taskName.trimmingCharacters(in: .whitespacesAndNewlines)
                                    )
                                }
                            }
                        }
                }
                .onPreferenceChange(ViewHeightKey.self) { height in
                    editorHeight = height
                }
                .onTapGesture {
                    isEditing = true
                }
                
                // Project name and dates
                VStack(alignment: .leading, spacing: 8) {
                    // Project name
                    Text(task.projectName)
                        .font(.system(size: 14))
                        .foregroundColor(Color("MySecondary"))
                    
                    // Dates
                    HStack(spacing: 16) {
                        // Create date
                        HStack(spacing: 4) {
                            Image(systemName: "sparkles.square.filled.on.square")
                                .font(.system(size: 12))
                            Text(formatDate(task.createTime))
                                .font(.system(size: 12))
                        }
                        .foregroundColor(Color("MyTertiary"))
                        
                        // Due date
                        HStack(spacing: 4) {
                            Image(systemName: "calendar.badge.clock")
                                .font(.system(size: 12))
                            Text(formatDate(task.dueDate))
                                .font(.system(size: 12))
                        }
                        .foregroundColor(Color("MyTertiary"))
                    }
                }
            }
            
            // 3. Edit and Delete buttons
            VStack(spacing: 12) {
                Button(action: onEdit) {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 16))
                        .foregroundColor(Color("MySecondary"))
                }
                
                Spacer()
                
                DeleteTaskButton(onDelete: onDelete)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 10)
        .background(Color("SideSheetBg").opacity(0.2))
        .withTransparentRectangleStyle()
        .overlay(
            Rectangle()
                .fill(priorityColor(task.priority))
                .frame(width: 3),
            alignment: .leading
        )
    }
}

// Helper for measuring height
struct ViewHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

