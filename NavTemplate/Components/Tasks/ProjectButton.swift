import SwiftUI
import NavTemplateShared

struct ProjectButton: View {
    @Binding var selectedProject: ProjectMetadata
    @StateObject private var projectModel = ProjectModel.shared
    
    var body: some View {
        Menu {
            ForEach(projectModel.sortedProjects, id: \.projId) { project in
                Button {
                    withAnimation {
                        selectedProject = project
                    }
                } label: {
                    HStack {
                        if let iconFilename = project.icon {
                            CachedAsyncImage(
                                source: .local(iconFilename),
                                width: 12,
                                height: 12
                            )
                        } else {
                            Image(systemName: "folder")
                                .font(.system(size: 12))
                        }
                        
                        Text(project.projectName)
                        
                        if selectedProject.projId == project.projId {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack {
                Group {
                    if let iconFilename = selectedProject.icon {
                        CachedAsyncImage(
                            source: .local(iconFilename),
                            width: 12,
                            height: 12
                        )
                    } else {
                        Image(systemName: "folder")
                            .font(.system(size: 12))
                    }
                }
                .id(selectedProject.projId)
                
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