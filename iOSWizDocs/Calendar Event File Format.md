# Overview

This document provides a formal specification for representing calendar events in JSON format for a Swift-based iOS system. This updated format adopts an **append-only update strategy** to efficiently handle event updates, duplicates, and reconciliation while maintaining compatibility with existing systems.

---

# Calendar Filename and Path

Calendar files are stored in the following path format:  
`Category Notes/Daily/YYYY/Calendar-YYYY.md`, where `YYYY` represents the year. Each calendar file contains JSON-formatted events, one event per line.

---

# Append-Only Update Strategy

### Overview

When an event update is required, the updated event entry is **appended** to the end of the file. This approach may result in multiple occurrences of the same event due to repeated updates. To manage this:

1. When reading the file, duplicates are filtered, retaining only the **last occurrence** of each event.
2. The **`CalendarUpdateCount`** variable in `UserDefaults` tracks the number of appended updates.
3. When the update count reaches a threshold (e.g., 100), the system reconciles the file by removing duplicates and rewriting the file with only the latest entries.

---

# Line Format Specification

Each event is stored as a JSON object on a separate line without any prefix. Example:

```json
{"eventId": 1703123456, "eventTitle": "Team Meeting", "startTime": 1703123456, "endTime": 1703123756, "projId": 1703123456, "reminders": [60, 30], "recurrence": "W", "notes": "Discuss Q1 goals with the team", "location": "123 Main St, Springfield", "url": "https://zoom.us/j/123456789"}
```

---

# Example Event Representation

## Single Event

```json
{"eventId": 1703123456, "eventTitle": "Team Meeting", "startTime": 1703123456, "endTime": 1703123756, "projId": 1703123456, "reminders": [60, 30], "recurrence": "W", "notes": "Discuss Q1 goals with the team", "location": "123 Main St, Springfield", "url": "https://zoom.us/j/123456789"}
```

## Multiple Events (After Updates)

```json
{"eventId": 1703123456, "eventTitle": "Team Meeting", "startTime": 1703123456, "endTime": 1703123756, "projId": 1703123456, "reminders": [60, 30], "recurrence": "W", "notes": "Discuss Q1 goals with the team", "location": "123 Main St, Springfield", "url": "https://zoom.us/j/123456789"}
{"eventId": 1703124000, "eventTitle": "Doctor's Appointment", "startTime": 1703124000, "endTime": 1703124300, "projId": null, "reminders": [15], "recurrence": null, "notes": "Routine check-up", "location": "456 Elm St, Springfield", "url": null}
{"eventId": 1703123456, "eventTitle": "Updated Team Meeting", "startTime": 1703123456, "endTime": 1703123756, "projId": 1703123456, "reminders": [45], "recurrence": "D", "notes": "Discuss updated goals with the team", "location": "124 Main St, Springfield", "url": "https://zoom.us/j/123456789"}
```

---

# CalendarEvent Field Descriptions

### Required Fields

1. **`eventId`**
    
    - **Type**: `Int`
    - **Description**: Unique identifier for the event, typically the timestamp of its creation.
    - **Example**: `1703123456`
2. **`eventTitle`**
    
    - **Type**: `String`
    - **Description**: Descriptive title of the event.
    - **Example**: `"Team Meeting"`
3. **`startTime`**
    
    - **Type**: `Int`
    - **Description**: Start time of the event as a Unix timestamp in seconds.
    - **Example**: `1703123456`
4. **`endTime`**
    
    - **Type**: `Int`
    - **Description**: End time of the event as a Unix timestamp in seconds.
    - **Example**: `1703123756`

### Optional Fields

1. **`projId`**: Identifier linking the event to a project. Example: `12345`.
2. **`reminders`**: Array of positive integers representing time offsets (in minutes) before the event when reminders will trigger. Example: `[60, 30]`.
3. **`recurrence`**: Single character specifying recurrence (`"D"`, `"W"`, `"M"`, or `null`).
4. **`notes`**: Additional details about the event.
5. **`location`**: Address of the meeting place.
6. **`url`**: Video conferencing URL.

---

# Reconciliation Workflow

### Trigger

Reconciliation occurs when `CalendarUpdateCount` reaches 100.

### Process

1. **Read**: Load all lines from the calendar file for the current year.
2. **Filter**: Parse each line into a `CalendarEvent` object and retain only the latest occurrence of each `eventId`.
3. **Rewrite**: Write the filtered events back to the file, eliminating duplicates.
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

### Reconciliation

```swift
func reconcileFile(at filePath: String) throws {
    let lines = try String(contentsOfFile: filePath).components(separatedBy: .newlines)
    var eventMap = [Int: String]() // eventId -> JSON string

    for line in lines {
        guard let data = line.data(using: .utf8),
              let event = try? JSONDecoder().decode(CalendarEvent.self, from: data) else { continue }
        eventMap[event.eventId] = line
    }

    let reconciledContent = eventMap.values.joined(separator: "\n") + "\n"
    try reconciledContent.write(toFile: filePath, atomically: true, encoding: .utf8)
}
```

---

# Key Considerations

1. **Incremental Appends**: Keeps the file size manageable until reconciliation.
2. **Efficient Filtering**: Deduplication ensures only the latest event entries are used.
3. **Scalability**: Handles large files by appending updates and periodic reconciliation.

---

# Conclusion

The append-only strategy simplifies updates and ensures data integrity while optimizing for read and write operations. By appending updates and reconciling periodically, this approach balances efficiency and maintainability for large datasets.