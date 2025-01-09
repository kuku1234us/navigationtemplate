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

Located in the FilterSidesheet, project filtering allows users to:

- Select/deselect individual projects
- Select/deselect all projects at once
- Reorder projects through drag and drop
- Projects are persisted in `ProjectSettings`:
  ```swift
  public struct ProjectSettings: Codable {
      public var selectedProjects: Set<Int64>  // Selected project IDs
      public var projectOrder: [Int64]         // Project display order
  }
  ```

## Task Filtering

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

Tasks can be sorted in three ways through the SortMenu:

1. **Task Creation** (Icon: `clock`, Selected: `clock.fill`)
   - **Description**: Sorts tasks by their creation timestamp in descending order.
   - **Behavior**: Newest tasks appear first, providing a chronological view of task creation.

2. **Proj Selected** (Icon: `list.bullet`, Selected: `list.bullet.indent`)
   - **Description**: Organizes tasks based on the order of their associated projects.
   - **Behavior**:
     - Projects are ordered as per the user's selection in the FilterSidesheet.
     - Within each project, tasks are first sorted by priority in descending order, ensuring that higher priority tasks appear first.
     - Tasks with the same priority are then sorted by creation time in descending order.

3. **Proj Modified** (Icon: `arrow.up.arrow.down`, Selected: `arrow.up.arrow.down.circle.fill`)
   - **Description**: Prioritizes projects that have been recently updated.
   - **Behavior**:
     - Projects are sorted by the most recent task's creation time within each project.
     - Ensures that tasks from the most recently active projects are displayed first.
     - Within each project, tasks are first sorted by priority in descending order, ensuring that higher priority tasks appear first.
     - Tasks with the same priority are then sorted by their creation time in descending order.

Sort order is managed by `TaskSortOrder`:

```swift
public enum TaskSortOrderType: String {
    case taskCreationDesc
    case projSelectedDesc
    case projModifiedDesc
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
