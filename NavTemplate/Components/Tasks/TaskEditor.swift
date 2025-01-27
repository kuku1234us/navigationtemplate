// NavTemplate/Components/Tasks/TaskEditor.swift

import SwiftUI
import NavTemplateShared

struct PriorityButton: View {
    @Binding var selectedPriority: TaskPriority
    
    var body: some View {
        Menu {
            ForEach([TaskPriority.urgent, .high, .normal, .low], id: \.self) { priority in
                Button {
                    selectedPriority = priority
                } label: {
                    HStack {
                        Circle()
                            .fill(priority.color)
                            .frame(width: 8, height: 8)
                        Text(priority.rawValue)
                        if priority == selectedPriority {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack {
                Circle()
                    .fill(selectedPriority.color)
                    .frame(width: 8, height: 8)
                Text(selectedPriority.rawValue)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 12))
            }
            .foregroundColor(Color("MySecondary"))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color("SideSheetBg").opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

struct TaskEditor: View {
    // For editing existing task
    let existingTask: TaskItem?
    @Binding var isPresented: Bool
    
    // State for task properties
    @State private var text: String = ""
    @FocusState private var isFocused: Bool
    @State private var selectedPriority: TaskPriority = .normal
    @State private var selectedProject: ProjectMetadata
    @StateObject private var projectModel = ProjectModel.shared
    @StateObject private var taskModel = TaskModel.shared
    
    // Initialize with optional task
    init(task: TaskItem? = nil, isPresented: Binding<Bool>) {
        self.existingTask = task
        self._isPresented = isPresented
        
        // Set initial values
        if let task = task {
            _text = State(initialValue: task.name)
            _selectedPriority = State(initialValue: task.priority)
            
            if let project = ProjectModel.shared.getProject(withId: task.projId) {
                _selectedProject = State(initialValue: project)
            } else {
                _selectedProject = State(initialValue: ProjectModel.shared.inboxProject)
            }
        } else {
            // For new task, use last selected project or inbox
            if let lastProject = ProjectModel.shared.getProject(withId: ProjectModel.shared.lastSelectedProjId) {
                _selectedProject = State(initialValue: lastProject)
            } else {
                _selectedProject = State(initialValue: ProjectModel.shared.inboxProject)
            }
        }
    }
    
    private func handleSave() {
        if let existingTask = existingTask {
            // Update existing task
            taskModel.updateTask(
                existingTask,
                newName: text.trimmingCharacters(in: .whitespacesAndNewlines),
                newPriority: selectedPriority,
                newProjId: selectedProject.projId
            )
        } else {
            // Create new task
            let newTask = TaskItem(
                id: Int64(Date().timeIntervalSince1970)*1000,
                name: text.trimmingCharacters(in: .whitespacesAndNewlines),
                taskStatus: .notStarted,
                priority: selectedPriority,
                projId: selectedProject.projId,
                dueDate: nil,
                tags: [],
                createTime: Date()
            )
            taskModel.addTask(newTask)
        }
        
        // Save the selected project as last used
        ProjectModel.shared.lastSelectedProjId = selectedProject.projId
        
        // Force a UI update
        DispatchQueue.main.async {
            taskModel.objectWillChange.send()
        }
        
        // Perform haptic feedback
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        
        // Dismiss the editor
        isPresented = false
    }
    
    var body: some View {
        VStack(spacing: 5) {
            // Title
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text("Task Name...")
                        .font(.system(size: 16))
                        .foregroundColor(Color("MyTertiary"))
                        .padding(.top, 8)
                        .padding(.leading, 5)
                }
                
                TextEditor(text: $text)
                    .font(.system(size: 16))
                    .foregroundColor(Color("MyPrimary"))
                    .frame(height: 40)
                    .scrollContentBackground(.hidden)
                    .focused($isFocused)
            }
            .padding(.horizontal, 16)
            
            VStack(alignment: .leading, spacing: 10) {
                // Priority Menu
                PriorityButton(selectedPriority: $selectedPriority)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Divider()
                    .background(Color("MyTertiary").opacity(0.3))                    
                
                // Project Menu and Save Button
                HStack {
                    ProjectButton(selectedProject: $selectedProject)
                    
                    Spacer()
                    
                    SaveIconButton(action: handleSave)
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 8)
        }
        .padding(.top, 16)
        .onAppear {
            isFocused = true
        }
    }
}

