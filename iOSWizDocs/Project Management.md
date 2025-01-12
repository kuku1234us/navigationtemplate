# Overview

The Project Management of the iOSWiz app is designed to efficiently manage Project Files in the Obsidian iCloud Vault. This includes managing project icons, maintaining project integrity, and any reconciliations work that is not easily done manually in Obsidian.

---

# Main App - Tasks Page

The Project Management functionalities are currently integrated in the Tasks Page of the iOSWiz Main App.

## loadProjects()

The `loadProjects()` function is a critical component of the `ProjectModel` class, responsible for loading and managing project data from the Obsidian iCloud Vault.

### Functionality

- **Load Project Files**: Retrieves all project files using `ProjectFileManager.shared.findAllProjectFiles()`.
- **Parse Metadata**: Extracts metadata from each project file, including `projId`, `banner`, `projectStatus`, `noteType`, `creationTime`, `modifiedTime`, `filePath`, and `icon`.
- **Update Settings**: Checks for new or removed projects and updates `projectOrder` and `selectedProjects` in `ProjectSettings`.
- **Sort Projects**: Sorts projects by `modifiedTime` in descending order to ensure the most recently modified projects are prioritized.
- **Notify UI**: Updates the `projects` array and sends a notification to refresh the UI.

### Reconciliation

- **Project ID Assignment**: When loading a project, if the frontmatter section does not include a `projId`, one is created based on the creation time of the project file and inserted into the frontmatter section of the project file.
- **Icon Cleanup**: After all projects have been loaded into memory, the UserDefaults will be checked for unused project icons, and any that are no longer associated with a project will be removed.

### Invocation

- **Initialization**: Automatically called during the initialization of `ProjectModel` to ensure the app starts with the latest project data.
- **Tasks Page**: Invoked when the `TasksPage` of the iOSWiz Main App appears, ensuring that any changes to projects are reflected in the UI.

### Integration with UserDefaults

- Saves the current state of projects to UserDefaults, allowing widgets to access and display project data efficiently.

# Task Widget

The Task Widget is a lightweight widget that displays a list of max 16 tasks. For this reason, the full project list and their metadata are not needed. The tasks are loaded from the `UserDefaults` with the key `WidgetTasks`. Each task in the list has `iconImageName` which is used to load the icon image from the `ImageCache`.
