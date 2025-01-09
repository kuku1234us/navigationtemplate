# Introduction

The iOSWiz Logger is a simple yet effective logging system designed for iOS applications. It allows developers to log messages with different severity levels and persist these logs for later review. This is particularly useful for debugging and monitoring app behavior over time.

# Features

- **Log Levels**: Supports Info, Debug, and Error levels.
- **Persistent Storage**: Logs are saved in `UserDefaults` for later retrieval.
- **Timestamping**: Each log entry is timestamped with the local time.
- **Target Identification**: Logs include the target (e.g., NavTemplate, NavWidget) for context.
- **Log Management**: Provides methods to retrieve and clear logs.

# Log Levels

1. **Info (`【Info】`)**: General information about app operations.
2. **Debug (`【Debug】`)**: Detailed information useful for debugging. Only available in DEBUG builds.
3. **Error (`【Error】`)**: Indicates a problem that needs attention.

# Usage

## Initialization

Create a logger instance for a specific target:

```swift
let logger = Logger(target: "NavTemplate")
```

## Logging Messages

Log messages at different levels:

```swift
logger.info("App started successfully")
logger.debug("Loading user data")
logger.error("Failed to load user data", error: someError)
```

## Retrieving Logs

Get all stored logs:

```swift
let logs = logger.getLogs()
```

## Clearing Logs

Clear all stored logs:

```swift
logger.clearLogs()
```

# Implementation Details

## Timestamp Format

Logs are timestamped using the format `YYYY-MM-DD#HH:MM:SS`, where `#` separates the date and time.

## Storage

Logs are stored in `UserDefaults` under the key `AppLogs`. The logger maintains a maximum of 1000 log entries to prevent excessive storage use.

## Thread Safety

The Logger class is marked as `@unchecked Sendable`, allowing it to be used across different threads. However, care should be taken to ensure thread safety when accessing shared resources.

# Example

```swift
let logger = Logger(target: "NavWidget")

logger.info("Widget initialized")
logger.debug("Fetching data for widget")
logger.error("Data fetch failed", error: someError)

// Retrieve and print logs
let logs = logger.getLogs()
logs.forEach { print($0) }

// Clear logs
logger.clearLogs()
```

# Conclusion

The iOSWiz Logger is a versatile tool for tracking application behavior and diagnosing issues. By providing persistent, timestamped logs, it helps developers maintain and improve their applications effectively.

