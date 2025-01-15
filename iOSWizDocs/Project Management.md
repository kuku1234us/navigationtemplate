# Introduction

The Project Management of the iOSWiz app is designed to efficiently manage Project Files in the Obsidian iCloud Vault. This includes managing project icons, maintaining project integrity, and any reconciliations work that is not easily done manually in Obsidian.

---

# Main App - Tasks Page

The Project Management functionalities are currently integrated in the Tasks Page of the iOSWiz Main App.

## loadProjects()

The `loadProjects()` function is a critical component of the `ProjectModel` class, responsible for loading and managing project data from the Obsidian iCloud Vault.

### Functionality

- **Load from ProjectsSummary.md**: The primary method for loading projects is through the `ProjectsSummary.md` file, which contains a JSON summary of all projects. This approach significantly reduces the need to traverse the entire Projects folder, improving efficiency.
- **Fallback to Reconciliation**: If loading from `ProjectsSummary.md` fails, the system falls back to `reconcileProjects()`, which scans the vault, updates project metadata, and regenerates the `ProjectsSummary.md` file.
- **Parse Metadata**: Extracts metadata from each project file, including `projId`, `banner`, `projectStatus`, `noteType`, `creationTime`, `modifiedTime`, `filePath`, and `icon`.
- **Update Settings**: Checks for new or removed projects and updates `projectOrder` and `selectedProjects` in `ProjectSettings`.
- **Sort Projects**: Sorts projects by `modifiedTime` in descending order to ensure the most recently modified projects are prioritized.
- **Notify UI**: Updates the `projects` array and sends a notification to refresh the UI.

### Reconciliation

- **Project ID Assignment**: When loading a project, if the frontmatter section does not include a `projId`, one is created based on the creation time of the project file and inserted into the frontmatter section of the project file.
- **Icon Cleanup**: After all projects have been loaded into memory, the UserDefaults will be checked for unused project icons, and any that are no longer associated with a project will be removed.
- **ProjectsSummary.md Update**: During reconciliation, the `ProjectsSummary.md` file is updated to reflect the current state of all projects, ensuring that future loads are efficient and accurate.
- **Task Reloading**: The `reconcileProjects()` process reloads all tasks from the project files and updates:
  - The main app's task list
  - The widget's task data through `updateWidgetTasks()`
  - Triggers a widget timeline reload to refresh the display

### Invocation

- **Initialization**: Automatically called during the initialization of `ProjectModel` to ensure the app starts with the latest project data.
- **Tasks Page**: Invoked when the `TasksPage` of the iOSWiz Main App appears, ensuring that any changes to projects are reflected in the UI.

### Integration with UserDefaults

- Saves the current state of projects to UserDefaults, allowing widgets to access and display project data efficiently.

# Task Widget

The Task Widget is a lightweight widget that displays a list of max 16 tasks. For this reason, the full project list and their metadata are not needed. The tasks are loaded from the `UserDefaults` with the key `WidgetTasks`. Each task in the list has `iconImageName` which is used to load the icon image from the `ImageCache`.

# ProjectsSummary.md

The `ProjectsSummary.md` file is a crucial component for efficient project management within the iOSWiz and ObsidianWiz apps. It contains a list of all projects in JSON format, allowing both applications to quickly access project files without needing to traverse the entire Projects folder.

## Path

- **Location**: The file is located at `Category Notes/Projects/ProjectsSummary.md` within the Obsidian iCloud Vault.

## Functionality

- **Efficient Access**: By maintaining a summary of all projects, the apps can quickly locate and access project files, significantly reducing the time and resources needed to manage projects.
- **Automatic Updates**: This file is automatically updated whenever project metadata changes, or when projects are added or removed. This ensures that the summary is always current and accurate.
- **JSON Format**: The use of JSON format allows for easy parsing and integration with various components of the apps, facilitating seamless project management.

## Usage

- **Project Loading**: During the project loading process, the `ProjectsSummary.md` file is referenced to quickly gather information about all available projects.
- **Project Synchronization**: Ensures that both iOSWiz and ObsidianWiz have synchronized views of the project data, enhancing consistency and reliability across platforms.


