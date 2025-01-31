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
{
    "eventId": 1703123456789,     // Unique identifier (timestamp + random)
    "eventTitle": "Team Meeting",
    "startTime": 1703123456,      // Unix timestamp
    "endTime": 1703127056,        // Unix timestamp
    "projId": 123,                // Project ID (optional)
    "reminders": [                // Array of reminder objects
        {
            "minutes": 0,         // Minutes before event (0 = at event time)
            "sound": "Elevator"   // Notification sound to play
        },
        {
            "minutes": 15,        // 15 minutes before
            "sound": "Game"       // Different sound for each reminder
        }
    ],
    "recurrence": "daily",        // Recurrence pattern (optional)
    "notes": "Discuss roadmap",   // Notes (optional)
    "location": "Room 101",       // Location (optional)
    "url": "https://meet.com/..." // Meeting URL (optional)
}
```

### Delete Marker

```json
{"eventId": 1703123456, "action": "delete"}
```

---

# Example Event Representation

## Multiple Events and Delete Marker

```json
{"eventId":1703123456789,"eventTitle":"Team Meeting","startTime":1703123456,"endTime":1703127056,"projId":123,"reminders":[{"minutes":0,"sound":"Elevator"},{"minutes":15,"sound":"Game"}]}
{"eventId":1703123456789,"eventTitle":"Team Meeting Updated","startTime":1703123456,"endTime":1703127056,"projId":123,"reminders":[{"minutes":0,"sound":"Elevator"}]}
{"eventId":1703123987654,"eventTitle":"Lunch","startTime":1703134567,"endTime":1703138167,"reminders":[{"minutes":5,"sound":"Flute"}]}
{"eventId":1703123456789,"action":"delete"}
```

After reconciliation, only undeleted and latest events are retained:

```json
{"eventId":1703123987654,"eventTitle":"Lunch","startTime":1703134567,"endTime":1703138167,"reminders":[{"minutes":5,"sound":"Flute"}]}
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
2. **`reminders`**: Reminders are stored as an array in the `CalendarEvent` object. Each reminder specifies the time before the event at which a notification should be triggered and the sound associated with the notification.
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

# Reminders Implementation

## ReminderType

The `ReminderType` struct is designed to facilitate structured reminders within calendar events. It conforms to `Codable` for seamless JSON encoding/decoding and `Hashable` to allow usage in sets and dictionary keys. These traits enable efficient data management and ensure compatibility with Swift's standard collection types

```swift
public struct ReminderType: Codable, Hashable {
    public let minutes: Int
    public let sound: String
    
    public init(minutes: Int, sound: String = DefaultNotificationSound) {
        self.minutes = minutes
        self.sound = sound
    }
    
    // For backward compatibility - convert from Int to ReminderType
    public static func from(_ minutes: Int) -> ReminderType {
        ReminderType(minutes: minutes)  // Will use DefaultNotificationSound
    }
    
    // For comparison and Set operations
    public func hash(into hasher: inout Hasher) {
        hasher.combine(minutes)
        hasher.combine(sound)
    }
    
    public static func == (lhs: ReminderType, rhs: ReminderType) -> Bool {
        return lhs.minutes == rhs.minutes && lhs.sound == rhs.sound
    }
}
```

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

### Appending CalenderEvent Updates

The `appendEvent()` method is a crucial component of `CalendarModel.swift`, designed to efficiently handle the addition of new events to the calendar file. This method first encoding the event object into a JSON string, ensuring that all event details are encapsulated. The JSON string is then appended to the end of the designated calendar file, which is organized by year. This append-only approach is integral to maintaining a chronological record of updates to this CalendarEvent object, allowing for straightforward updates and deletions without the need for complex file manipulations.

The method also incorporates a mechanism to track the number of updates made to the calendar file. This is achieved through the `CalendarUpdateCount` variable stored in `UserDefaults`, which is incremented with each new event appended. When this count reaches a predefined threshold, currently set at 100, the system triggers a reconciliation process. This process involves reading the entire file, filtering out duplicate entries, and rewriting the file to include only the most recent version of each event, thereby optimizing file size and speed of future reads. By leveraging this method, the system effectively balances the need for real-time updates with the long-term maintenance of the calendar data, providing a robust solution for managing calendar events in a dynamic environment.

### Appending Delete Markers

The use of delete markers in our calendar event management system is a strategic choice designed to maintain the integrity and efficiency of the append-only file structure. In traditional file systems, deleting an entry often involves directly modifying the file, which can be both time-consuming and error-prone, especially in systems where data integrity is paramount. Instead, our system appends a delete marker to the file whenever an event is deleted. This marker is a simple JSON object that contains the `eventId` of the event to be deleted and an `"action": "delete"` field. By appending this marker, we avoid the need for immediate file restructuring, thus preserving the chronological integrity of the file.

The delete marker serves as an instruction for the reconciliation process, which is triggered when the `CalendarUpdateCount` reaches a certain threshold. During reconciliation, the system reads through the entire file, identifying and removing any events that have corresponding delete markers. This ensures that the file remains up-to-date and free of obsolete entries, without the need for constant manual intervention. The use of delete markers thus provides a robust and scalable solution for managing deletions, allowing the system to handle large volumes of data efficiently while maintaining a clear and accurate record of all events.

---

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