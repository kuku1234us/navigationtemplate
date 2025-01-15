# Overview

The Tasks Page is the primary interface in the iOSWiz Main App for Task Management. It presents a list of tasks in preselected sort order. There is a quick add "+" button at the bottom. A FilterSidesheet is provided to manage Projects.

## Page Structure

### Header Section

- **Title**: Displays the page title, typically "Tasks".
- **Sort Menu**: Allows users to change the sort order of tasks (e.g., by creation date, priority).

### Task List

- **TaskItemView**: Each task is displayed with its name, status, priority, and associated project.
- **Dynamic Updates**: The list updates in real-time based on changes in task data or filter settings.
- **Actions**: Users can edit or delete tasks directly from the list.

### Quick Add Button

- **AddTaskButton**: A floating button at the bottom right corner of the page.
- **Functionality**: Tapping the button opens a task creation interface, allowing users to quickly add new tasks.

### FilterSidesheet

- **Project Filtering**: Users can filter tasks by selecting or deselecting projects.
- **Reconciliation**: Includes a button to refresh project data, ensuring the task list is up-to-date.
- **Integration**: The side sheet interacts with the task list to dynamically update the displayed tasks based on the selected filters.

## TasksPage Loading Process

1. **Initialization**:
   - When the Tasks Page is initialized, it sets up the main components: `TaskListView`, `AddTaskButton`, and `FilterSidesheet`.
   - During the creation of `FilterSidesheet`, the `ProjectModel` singleton is initialized:

   ```swift
   // In FilterSidesheet.swift
   struct FilterSidesheet: View {
       @StateObject private var projectModel = ProjectModel.shared
       // This initialization triggers ProjectModel's init() which loads projects
   }
   ```

   - The `ProjectModel` singleton's initialization triggers the loading of projects:

   ```swift
   // In ProjectModel.swift
   public class ProjectModel: ObservableObject {
       public static let shared = ProjectModel()
       
       private init() {
           self.settings = Self.loadProjectSettings()
           Task {
               await loadProjects()  // Load projects during initialization
           }
       }
   }
   ```

   - The `TasksPage` then sets up its view hierarchy:

   ```swift
   struct TasksPage: View {
       @StateObject private var taskModel = TaskModel.shared

       var body: some View {
           VStack {
               HeaderView()
               TaskListView()
               AddTaskButton()
           }
           .sheet(isPresented: $showFilterSheet) {
               FilterSidesheet()
           }
           .onAppear {
               // Trigger task loading
               taskModel.loadAllTasks()
               // Process any pending task updates from widget
               TaskModel.shared.processPendingTaskUpdates()
           }
       }
   }
   ```

2. **Project Loading**:
   - The `ProjectModel` is responsible for loading projects.
   - It first attempts to load projects from the `ProjectsSummary.md` file, which provides a quick summary of all projects.
   - If loading from the summary fails, `ProjectModel` falls back to the `reconcileProjects()` method, which scans the vault for project files, updates metadata, and regenerates the `ProjectsSummary.md` file.
   - Once projects are loaded, `ProjectModel` updates the `TaskModel` with tasks extracted from the project files.

   ```swift
   @MainActor
   public func loadProjects() async {
       do {
           if let projects = try loadFromProjectsSummary() {
               self.projects = projects
               updateTaskModelWithProjects(projects)
               return
           }
           await reconcileProjects()
       } catch {
           await reconcileProjects()
       }
   }
   ```

3. **Task Loading**:
   - The `TaskModel` listens for changes in the `ProjectModel` to load tasks.
   - It retrieves tasks from the project files using `ProjectFileManager`.
   - Tasks are parsed and stored in the `TaskModel`, which then applies the current sort order to organize the tasks.

   ```swift
   public func loadAllTasks() {
       do {
           let markdownFiles = try projectFileManager.findAllMarkdownFiles()
           var allTasks: [TaskItem] = []
           for fileURL in markdownFiles {
               if let (content, projId) = try projectFileManager.readProjectFile(fileURL) {
                   if let tasks = projectFileManager.parseTasksFromContent(content, projId: projId) {
                       allTasks.append(contentsOf: tasks)
                   }
               }
           }
           self.tasks = allTasks
           applySortOrder(TaskSortOrder.shared.currentOrder)
           updateWidgetTasks()
       } catch {
           print("Error loading tasks: \(error)")
       }
   }
   ```

4. **UI Update**:
   - The `TaskListView` observes the `TaskModel` for changes.
   - When tasks are loaded or updated, `TaskListView` refreshes to display the current list of tasks.
   - The UI dynamically updates to reflect changes in task data or filter settings.

   ```swift
   struct TaskListView: View {
       @ObservedObject var taskModel = TaskModel.shared
       var body: some View {
           List(taskModel.tasks) { task in
               TaskItemView(task: task)
           }
       }
   }
   ```

5. **Filter and Sort Integration**:
   - The `FilterSidesheet` allows users to filter tasks by project.
   - The sort menu in the header section lets users change the sort order of tasks.
   - Both filtering and sorting are integrated into the task loading process, ensuring that the displayed tasks match the user's preferences.

   ```swift
   struct FilterSidesheet: View {
       @StateObject private var projectModel = ProjectModel.shared
       var body: some View {
           VStack {
               // Project selection and reconciliation logic
           }
       }
   }
   ```

This process ensures that the Tasks Page is always up-to-date with the latest project and task data, providing a seamless user experience.

