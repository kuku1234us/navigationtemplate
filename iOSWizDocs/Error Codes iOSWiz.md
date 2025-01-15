# List of Error Codes used in iOSWiz

## Project Management Errors (E0xx)

| Code  | Description | Context (Method) |
|-------|-------------|-----------------|
| E001  | Failed to access Obsidian vault | `ProjectFileManager.findAllMarkdownFiles()` |
| E002  | Failed to create project file | `ProjectFileManager.createProjectFile(_:)` |
| E003  | Failed to update project file | `ProjectFileManager.updateProjectFile(_:)` |
| E004  | Failed to delete project file | `ProjectFileManager.deleteProjectFile(_:)` |
| E005  | Failed to move project file | `ProjectFileManager.moveProjectFile(_:)` |
| E006  | Failed to load project metadata | `ProjectModel.loadProjectMetadata()` |
| E007  | Failed to save project settings | `ProjectModel.saveProjectSettings()` |
| E008  | Failed to load project settings | `ProjectModel.loadProjectSettings()` |
| E009  | Failed to initialize project model | `ProjectModel.init()` |
| E010  | Failed to reconcile projects | `ProjectModel.reconcileProjects()` |

## Frontmatter Errors (E01x)

| Code  | Description | Context (Method) |
|-------|-------------|-----------------|
| E011  | Failed to find opening frontmatter marker | `ProjectModel.parseProjectMetadata(from:)` |
| E012  | Failed to find closing frontmatter marker | `ProjectModel.parseProjectMetadata(from:)` |
| E013  | Invalid frontmatter format | `ProjectModel.validateFrontmatter(_:)` |
| E014  | Missing required frontmatter fields | `ProjectModel.checkRequiredFields(_:)` |

