# List of Error Codes used in iOSWiz

## Project Management Errors

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

## Frontmatter Errors

| Code  | Description | Context (Method) |
|-------|-------------|-----------------|
| E011  | Failed to find opening frontmatter marker | `ProjectModel.parseProjectMetadata(from:)` |
| E012  | Failed to find closing frontmatter marker | `ProjectModel.parseProjectMetadata(from:)` |
| E013  | Invalid frontmatter format | `ProjectModel.validateFrontmatter(_:)` |
| E014  | Missing required frontmatter fields | `ProjectModel.checkRequiredFields(_:)` |

## Calendar Errors

| Code  | Description | Context (Method) |
|-------|-------------|-----------------|
| E015  | Failed to access vault while loading calendar events | `CalendarModel.loadEventsForYear(_:)` |
| E016  | Failed to load events for specified year | `CalendarModel.loadEventsForYear(_:)` |
| E017  | Failed to create calendar file | `CalendarModel.createCalendarFile(for:)` |
| E018  | Failed to save event | `CalendarModel.saveEvent(_:)` |
| E019  | Failed to update event | `CalendarModel.updateEvent(_:)` |
| E020  | Failed to delete event | `CalendarModel.deleteEvent(withId:)` |
| E021  | Failed to reconcile calendar file | `CalendarModel.reconcileFile(for:)` |
| E022  | Failed to parse event data | `CalendarModel.parseEventData(_:)` |
| E023  | Failed to delete event | `CalendarModel.deleteEvent(withId:)` |

## Calendar Errors

| Code  | Description | Context (Method) |
|-------|-------------|-----------------|
| E024  | Failed to schedule notification | `NotificationModel.scheduleEventReminders(for:)` |
| E025  | Failed to request notification authorization | `NotificationModel.requestAuthorization()` |

