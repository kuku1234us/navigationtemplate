import SwiftUI
import NavTemplateShared

struct CustomCheckbox: View {
    let isChecked: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: isChecked ? "checkmark.square.fill" : "square")
                .symbolRenderingMode(.hierarchical)
                .foregroundColor(isChecked ? Color("Accent") : Color("MySecondary"))
                .font(.system(size: 20))
        }
    }
}

struct TaskItemView: View {
    let task: NavTemplateShared.TaskItem
    let onEdit: () -> Void
    @State private var taskName: String
    @State private var isChecked: Bool
    @State private var isEditing: Bool = false
    @State private var editorHeight: CGFloat = 30
    
    init(task: NavTemplateShared.TaskItem, onEdit: @escaping () -> Void) {
        self.task = task
        self.onEdit = onEdit
        _taskName = State(initialValue: task.name)
        _isChecked = State(initialValue: task.isCompleted)
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
            CustomCheckbox(isChecked: isChecked) {
                isChecked.toggle()
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
                
                Button(action: {
                    // TODO: Add delete action
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 16))
                        .foregroundColor(Color("MySecondary"))
                }
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

