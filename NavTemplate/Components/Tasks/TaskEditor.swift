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

struct ProjectButton: View {
    @Binding var selectedProject: ProjectMetadata
    @StateObject private var projectModel = ProjectModel.shared
    
    var body: some View {
        Menu {
            ForEach(projectModel.projects, id: \.projId) { project in
                Button {
                    selectedProject = project
                } label: {
                    HStack {
                        Image(systemName: project.icon)
                            .font(.system(size: 12))
                            .foregroundColor(Color("MySecondary"))
                        Text(project.projectName)
                        if project.projId == selectedProject.projId {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack {
                Image(systemName: selectedProject.icon)
                    .font(.system(size: 12))
                Text(selectedProject.projectName)
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

struct SaveButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(Color("Accent"))
                .background(
                    Circle()
                        .fill(Color("SideSheetBg"))
                        .frame(width: 22, height: 22)
                )
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
        _text = State(initialValue: task?.name ?? "")
        _selectedPriority = State(initialValue: task?.priority ?? .normal)
        
        // Set initial project (Inbox for new tasks, or existing project)
        if let task = task,
           let project = ProjectModel.shared.getProject(atPath: task.projectFilePath) {
            _selectedProject = State(initialValue: project)
        } else {
            // Default to Inbox project
            _selectedProject = State(initialValue: ProjectModel.shared.inboxProject)
        }
    }
    
    var body: some View {
        VStack(spacing: 5) {
            // Text Editor with placeholder
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
                    
                    SaveButton {
                        if let existingTask = existingTask {
                            // Update existing task
                            taskModel.updateTask(
                                existingTask,
                                newName: text.trimmingCharacters(in: .whitespacesAndNewlines),
                                newPriority: selectedPriority,
                                newProjectPath: selectedProject.filePath
                            )
                        } else {
                            // Create new task
                            let newTask = TaskItem(
                                id: Int64(Date().timeIntervalSince1970)*1000,
                                name: text.trimmingCharacters(in: .whitespacesAndNewlines),
                                taskStatus: .notStarted,
                                priority: selectedPriority,
                                projectName: selectedProject.projectName,
                                projectFilePath: selectedProject.filePath,
                                dueDate: nil,
                                tags: [],
                                createTime: Date()
                            )
                            taskModel.addTask(newTask)
                        }
                        
                        // Force a UI update
                        DispatchQueue.main.async {
                            taskModel.objectWillChange.send()
                        }
                        
                        // Perform haptic feedback
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        
                        // Dismiss the editor
                        isPresented = false
                    }
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

