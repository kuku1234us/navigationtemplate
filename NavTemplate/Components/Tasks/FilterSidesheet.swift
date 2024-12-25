import SwiftUI
import NavTemplateShared

// Project Row Component
struct ProjectRow: View {
    let project: ProjectMetadata
    let isTargeted: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                // Icon with fixed width container
                Image(systemName: project.icon)
                    .font(.system(size: 16))
                    .foregroundColor(
                        ProjectModel.shared.isProjectSelected(project.projId)
                            ? Color("MySecondary")
                            : Color("MyTertiary")
                    )
                    .frame(width: 24)  // Fixed width for all icons
                
                Text(project.projectName)
                    .foregroundColor(
                        ProjectModel.shared.isProjectSelected(project.projId)
                            ? Color("MyPrimary")
                            : Color("MyTertiary")
                    )
                Spacer()
                
                Image(systemName: "line.3.horizontal")
                    .foregroundColor(Color("MyTertiary"))
                    .padding(.leading, 8)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(
                ProjectModel.shared.isProjectSelected(project.projId)
                    ? Color.black.opacity(0.3)
                    : Color.clear
            )
            .background(isTargeted ? Color("MySecondary").opacity(0.1) : Color.clear)
        }
    }
}

// Draggable Project Row Component
struct DraggableProjectRow: View {
    let project: ProjectMetadata
    let isTargeted: Bool
    let onToggle: () -> Void
    let onDrop: ([ProjectMetadata], CGPoint) -> Bool
    let onTargeted: (Bool) -> Void
    
    var body: some View {
        ProjectRow(
            project: project,
            isTargeted: isTargeted,
            onToggle: onToggle
        )
        .draggable(project) {
            HStack {
                Image(systemName: project.icon)
                Text(project.projectName)
            }
            .padding(8)
            .background(Color("SideSheetBg"))
            .cornerRadius(8)
        }
        .dropDestination(for: ProjectMetadata.self, 
            action: onDrop,
            isTargeted: onTargeted
        )
    }
}

// Project List Component
struct ProjectList: View {
    @ObservedObject var projectModel: ProjectModel
    @Binding var draggedProject: ProjectMetadata?
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(projectModel.sortedProjects, id: \.projId) { project in
                    DraggableProjectRow(
                        project: project,
                        isTargeted: draggedProject?.projId == project.projId,
                        onToggle: { projectModel.toggleProjectSelection(project.projId) },
                        onDrop: { items, location in
                            guard let draggedProject = items.first else { return false }
                            
                            // Get current order
                            var newOrder = projectModel.projects.map { $0.projId }
                            if projectModel.settings.projectOrder.isEmpty {
                                // If no order set yet, use current order
                                projectModel.updateProjectSettings(projectOrder: newOrder)
                            } else {
                                newOrder = projectModel.settings.projectOrder
                            }
                            
                            // Get indices
                            guard let fromIndex = newOrder.firstIndex(of: draggedProject.projId),
                                  let toIndex = newOrder.firstIndex(of: project.projId) else {
                                print("Indices not found - from: \(draggedProject.projId) to: \(project.projId)")
                                print("Current order: \(newOrder)")
                                return false
                            }
                            
                            // Move item
                            newOrder.remove(at: fromIndex)
                            newOrder.insert(draggedProject.projId, at: toIndex)
                            
                            // Update settings
                            projectModel.updateProjectSettings(projectOrder: newOrder)
                            return true
                        },
                        onTargeted: { isTargeted in
                            if isTargeted {
                                self.draggedProject = project
                            }
                        }
                    )
                }
            }
            .padding(.vertical)
        }
    }
}

// Main FilterSidesheet view
struct FilterSidesheet: View {
    @StateObject private var taskModel = TaskModel.shared
    @StateObject private var projectModel = ProjectModel.shared
    @State private var draggedProject: ProjectMetadata?
    
    private var areAllProjectsSelected: Bool {
        let allProjectIds = Set(projectModel.projects.map { $0.projId })
        return projectModel.settings.selectedProjects == allProjectIds
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with select all checkbox
            ZStack {
                // Select all button on left
                HStack {
                    Button {
                        if areAllProjectsSelected {
                            // Deselect all
                            projectModel.updateProjectSettings(selectedProjects: [])
                        } else {
                            // Select all
                            let allProjectIds = Set(projectModel.projects.map { $0.projId })
                            projectModel.updateProjectSettings(selectedProjects: allProjectIds)
                        }
                    } label: {
                        Image(systemName: areAllProjectsSelected ? "checkmark.square.fill" : "square")
                            .foregroundColor(areAllProjectsSelected ? Color("Accent") : Color("MySecondary"))
                            .font(.system(size: 16))
                    }
                    .padding(.leading, 16)
                    
                    Spacer()
                }
                
                // Centered title
                Text("Projects")
                    .font(.system(size: 17, weight: .black))
                    .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 16)
            
            Divider()
            
            ProjectList(
                projectModel: projectModel,
                draggedProject: $draggedProject
            )
            
            TaskFilterMenu()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("SideSheetBg"))
    }
} 