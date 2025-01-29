# Overview

This document provides a formal specification for representing calendar events in JSON format for a Swift-based iOS system. This updated format adopts an **append-only update strategy** to efficiently handle event updates, deletions, duplicates, and reconciliation while maintaining compatibility with existing systems.

---

# Calendar Filename and Path

Calendar files are stored in the following path format:  
`Category Notes/Daily/YYYY/Calendar-YYYY.md`, where `YYYY` represents the year. Each calendar file contains JSON-formatted events, one event per line.

---

# Append-Only Update and Delete Strategy

### Overview

When an event update or delete operation is required, the action is **appended** to the end of the file. This approach may result in multiple occurrences of the same event due to repeated updates or delete markers. To manage this:

1. When reading the file, duplicates are filtered, retaining only the **last occurrence** of each event, while ignoring any events marked for deletion.
2. The **`CalendarUpdateCount`** variable in `UserDefaults` tracks the number of appended updates or deletions.
3. When the update count reaches a threshold (e.g., 100), the system reconciles the file by removing duplicates and rewrite the file with only the latest entries, excluding deleted events.

---

# Line Format Specification

Each event or delete marker is stored as a JSON object on a separate line. Examples:

### Event Entry

```json
{"eventId": 1703123456, "eventTitle": "Team Meeting", "startTime": 1703123456, "endTime": 1703123756, "projId": 1703123456, "reminders": [60, 30], "recurrence": "W", "notes": "Discuss Q1 goals with the team", "location": "123 Main St, Springfield", "url": "https://zoom.us/j/123456789"}
```

### Delete Marker

```json
{"eventId": 1703123456, "action": "delete"}
```

---

# Example Event Representation

## Multiple Events and Delete Marker

```json
{"eventId": 1703123456, "eventTitle": "Team Meeting", "startTime": 1703123456, "endTime": 1703123756, "projId": 1703123456, "reminders": [60, 30], "recurrence": "W", "notes": "Discuss Q1 goals with the team", "location": "123 Main St, Springfield", "url": "https://zoom.us/j/123456789"}
{"eventId": 1703124000, "eventTitle": "Doctor's Appointment", "startTime": 1703124000, "endTime": 1703124300, "projId": null, "reminders": [15], "recurrence": null, "notes": "Routine check-up", "location": "456 Elm St, Springfield", "url": null}
{"eventId": 1703123456, "action": "delete"}
```

After reconciliation, only undeleted and latest events are retained:

```json
{"eventId": 1703124000, "eventTitle": "Doctor's Appointment", "startTime": 1703124000, "endTime": 1703124300, "projId": null, "reminders": [15], "recurrence": null, "notes": "Routine check-up", "location": "456 Elm St, Springfield", "url": null}
```

---

# CalendarEvent Field Descriptions

### Required Fields

1. **`eventId`**
    
    - **Type**: `Int`
    - **Description**: Unique identifier for the event, typically the timestamp of its creation.
    - **Example**: `1703123456`
2. **`action`** (only for delete markers)
    
    - **Type**: `String`
    - **Description**: Indicates the action to perform. For deletions, use `"delete"`.
    - **Example**: `"delete"`
3. **`eventTitle`** (for events)
    
    - **Type**: `String`
    - **Description**: Descriptive title of the event.
    - **Example**: `"Team Meeting"`
4. **`startTime`** (for events)
    
    - **Type**: `Int`
    - **Description**: Start time of the event as a Unix timestamp in seconds.
    - **Example**: `1703123456`
5. **`endTime`** (for events)
    
    - **Type**: `Int`
    - **Description**: End time of the event as a Unix timestamp in seconds.
    - **Example**: `1703123756`

### Optional Fields for Events

1. **`projId`**: Identifier linking the event to a project. Example: `12345`.
2. **`reminders`**: Array of ReminderInfo objects
   - Each reminder contains:
     ```json
     {
         "minutes": 15,  // Int: Minutes before event
         "sound": "Game" // String: Sound name without extension
     }
     ```
3. **`recurrence`**: Single character specifying recurrence (`"D"`, `"W"`, `"M"`, `"A"`, or `null`).
4. **`notes`**: Additional details about the event.
5. **`location`**: Address of the meeting place.
6. **`url`**: Video conferencing URL.

---

# Reconciliation Workflow

### Trigger

Reconciliation occurs when `CalendarUpdateCount` reaches 100.

### Process

1. **Read**: Load all lines from the calendar file for the current year.
2. **Filter**: Parse each line into a `CalendarEvent` object.
    - Retain only the latest occurrence of each `eventId`.
    - Exclude any `eventId` that has a corresponding `delete` action.
3. **Rewrite**: Write the filtered events back to the file, eliminating duplicates and deleted events.
4. **Reset Counter**: Set `CalendarUpdateCount` to 0.

---

# Integration in Swift

### Appending Updates

```swift
func appendEvent(to filePath: String, event: CalendarEvent) throws {
    let encoder = JSONEncoder()
    encoder.outputFormatting = .withoutEscapingSlashes
    let eventJSON = String(data: try encoder.encode(event), encoding: .utf8)!

    let fileHandle = try FileHandle(forWritingTo: URL(fileURLWithPath: filePath))
    defer { fileHandle.closeFile() }
    fileHandle.seekToEndOfFile()
    fileHandle.write("\(eventJSON)\n".data(using: .utf8)!)

    // Increment the update counter
    let updateCount = UserDefaults.standard.integer(forKey: "CalendarUpdateCount") + 1
    UserDefaults.standard.set(updateCount, forKey: "CalendarUpdateCount")

    // Perform reconciliation if threshold is reached
    if updateCount >= 100 {
        try reconcileFile(at: filePath)
        UserDefaults.standard.set(0, forKey: "CalendarUpdateCount")
    }
}
```

### Appending Delete Markers

```swift
func deleteEvent(from filePath: String, eventId: Int) throws {
    let deleteMarker = ["eventId": eventId, "action": "delete"]
    let deleteJSON = String(data: try JSONSerialization.data(withJSONObject: deleteMarker), encoding: .utf8)!

    let fileHandle = try FileHandle(forWritingTo: URL(fileURLWithPath: filePath))
    defer { fileHandle.closeFile() }
    fileHandle.seekToEndOfFile()
    fileHandle.write("\(deleteJSON)\n".data(using: .utf8)!)

    // Increment the update counter
    let updateCount = UserDefaults.standard.integer(forKey: "CalendarUpdateCount") + 1
    UserDefaults.standard.set(updateCount, forKey: "CalendarUpdateCount")

    // Perform reconciliation if threshold is reached
    if updateCount >= 100 {
        try reconcileFile(at: filePath)
        UserDefaults.standard.set(0, forKey: "CalendarUpdateCount")
    }
}
```

### Reconciliation

```swift
func reconcileFile(at filePath: String) throws {
    let lines = try String(contentsOfFile: filePath).components(separatedBy: .newlines)
    var eventMap = [Int: String]() // eventId -> JSON string
    var deleteSet = Set<Int>() // eventIds marked for deletion

    for line in lines {
        guard let data = line.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { continue }

        if let action = json["action"] as? String, action == "delete",
           let eventId = json["eventId"] as? Int {
            deleteSet.insert(eventId)
        } else if let eventId = json["eventId"] as? Int {
            eventMap[eventId] = line
        }
    }

    // Remove events marked for deletion
    for eventId in deleteSet {
        eventMap.removeValue(forKey: eventId)
    }

    let reconciledContent = eventMap.values.joined(separator: "\n") + "\n"
    try reconciledContent.write(toFile: filePath, atomically: true, encoding: .utf8)
}
```

---

# Key Considerations

1. **Incremental Appends**: Keeps the file size manageable until reconciliation.
2. **Efficient Filtering**: Deduplication ensures only the latest event entries are used, and deleted events are excluded.
3. **Scalability**: Handles large files by appending updates and periodic reconciliation.

---

# Conclusion

The append-only strategy simplifies updates and deletes while ensuring data integrity. By appending delete markers and reconciling periodically, this approach balances efficiency and maintainability for large datasets.