---
parent: "[[iOSWiz]]"
banner: https://cdn.midjourney.com/c6574714-48a3-48d4-a1ec-e7092e62b006/0_0.jpeg
---

# Introduction

The Tasks filtering and sorting system provides flexible ways to organize and view tasks based on various criteria. It consists of three main components:

- Project filtering through FilterSidesheet
- Task status and priority filtering through TaskFilterMenu
- Task sorting through SortMenu

# Filtering

## Project Filtering

Project filtering is a crucial part of the task management system, allowing users to control which projects' tasks are visible and how they are ordered. This functionality is primarily managed through the `FilterSidesheet` and the `ProjectSettings` structure.

### FilterSidesheet and Project List

- **FilterSidesheet**: This component provides a user interface for selecting and ordering projects. It displays a list of projects, each represented by a `ProjectRow` or `DraggableProjectRow` component.
- **Project Selection**: Users can select or deselect projects by tapping on them. The selection state is visually indicated and is managed by toggling the project's ID in the `selectedProjects` set within `ProjectSettings`.
- **Project Reordering**: Projects can be reordered via drag-and-drop functionality. The order is stored in the `projectOrder` array within `ProjectSettings`.

### ProjectSettings Structure

- **Definition**: `ProjectSettings` is a Codable structure that maintains the user's project selection and order preferences.
  ```swift
  public struct ProjectSettings: Codable {
      public var selectedProjects: Set<Int64>  // Selected project IDs
      public var projectOrder: [Int64]         // Project display order
  }
  ```
- **Storage and Loading**: 
  - `ProjectSettings` are stored in `UserDefaults` to persist user preferences across app launches.
  - They are loaded during the initialization of `ProjectModel` to restore the user's previous settings.
  - The settings are encoded and decoded using `JSONEncoder` and `JSONDecoder`, ensuring a consistent format.

### Maintenance and Updates

- **Automatic Updates**: `ProjectSettings` are automatically updated whenever a user selects, deselects, or reorders projects. This is handled by the `updateProjectSettings` method in `ProjectModel`.
- **Saving to UserDefaults**: Whenever `ProjectSettings` change, they are saved to `UserDefaults` to ensure persistence. This occurs in the `didSet` observer of the `settings` property in `ProjectModel`.
- **Loading from UserDefaults**: On app launch, `ProjectSettings` are loaded from `UserDefaults` to restore the user's previous project selections and order.

### Impact on Task Sorting

- **Task Sorting**: The order of projects in `ProjectSettings` directly influences the task sorting order when the "Proj Selected" sort option is active. Tasks are grouped and ordered based on their associated project's position in the `projectOrder` array.
- **Dynamic Updates**: Changes to project selection or order immediately affect the task list, providing a dynamic and responsive user experience.

# Task Filtering

The TaskFilterMenu provides filtering by:

- Task Status (Not Started, In Progress, Completed)
- Task Priority (Urgent, High, Normal, Low)

Filters are stored in `TaskFilterToggleSet`:

```swift
public struct TaskFilterToggleSet: Codable {
    public var priorities: Set<TaskPriority>
    public var statuses: Set<TaskStatus>
}
```

# Sorting

Tasks can be sorted in four ways through the SortMenu:

1. **Task Creation** (Icon: `calendar.badge.clock`, Selected: `calendar.badge.clock.fill`)
   - **Description**: Sorts tasks by their creation timestamp in descending order.
   - **Behavior**: Newest tasks appear first, providing a chronological view of task creation.

2. **Proj Selected** (Icon: `document.badge.clock`, Selected: `document.badge.clock.fill`)
   - **Description**: Organizes tasks based on the order of their associated projects.
   - **Behavior**:
     - Projects are ordered as per the user's selection in the `FilterSidesheet`.
     - Within each project, tasks are first sorted by priority in descending order, ensuring that higher priority tasks appear first.
     - Tasks with the same priority are then sorted by creation time in descending order.

3. **Proj Modified** (Icon: `document.badge.clock`, Selected: `document.badge.clock.fill`)
   - **Description**: Prioritizes projects that have been recently updated.
   - **Behavior**:
     - Projects are sorted by the most recent task's creation time within each project.
     - Ensures that tasks from the most recently active projects are displayed first.
     - Within each project, tasks are first sorted by priority in descending order, ensuring that higher priority tasks appear first.
     - Tasks with the same priority are then sorted by their creation time in descending order.

4. **Priority** (Icon: `smallcircle.filled.circle`, Selected: `smallcircle.filled.circle.fill`)
   - **Description**: Sorts tasks by their priority level in descending order.
   - **Behavior**:
     - Tasks with higher priority levels (e.g., Urgent, High) appear before those with lower priority levels (e.g., Normal, Low).
     - Within the same priority level, tasks are sorted by their creation time in descending order.

Sort order is managed by `TaskSortOrder`:

```swift
public enum TaskSortOrderType: String {
    case taskCreationDesc
    case projSelectedDesc
    case projModifiedDesc
    case priorityDesc
}
```

# Implementation Details

## Sort Order Persistence

- Current sort order is saved in UserDefaults
- Restored when app launches

## Sort Order Updates

- Changes trigger immediate UI updates
- Notification system for cross-component communication:

```swift
NotificationCenter.default.post(
    name: .taskSortOrderDidChange,
    object: nil,
    userInfo: ["sortOrder": newOrder]
)
```

## Filter State Persistence

- Filter selections are saved in UserDefaults
- Automatically restored on app launch

# Usage Example

```swift
// Apply filters and sort
taskModel.updateFilterToggles(
    priorities: [.urgent, .high],
    statuses: [.notStarted, .inProgress]
)

TaskSortOrder.shared.setOrder(.projModifiedDesc)
```
