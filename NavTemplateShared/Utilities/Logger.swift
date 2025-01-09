import Foundation
import Combine

public class Logger: @unchecked Sendable {
    // Private static instance
    private static var _shared: Logger?
    
    // Public shared instance accessor
    public static var shared: Logger {
        get {
            if _shared == nil {
                fatalError("Logger not initialized. Call Logger.initialize(target:) first")
            }
            return _shared!
        }
    }
    
    // Public initializer to be called by main targets only
    public static func initialize(target: String) {
        guard _shared == nil else {
            print("Warning: Logger already initialized")
            return
        }
        _shared = Logger(target: target)
    }
    
    private let target: String
    private let userDefaults: UserDefaults
    private let logsKey = "AppLogs"
    private let maxLogLines = 1000  // Limit number of log lines to prevent excessive storage use
    
    public enum LogLevel: String {
        case info = "【Info】"
        case debug = "【Debug】"
        case error = "【Error】"
    }
    
    // Make init private to prevent direct instantiation
    private init(target: String) {
        self.target = target
        self.userDefaults = UserDefaults(suiteName: "group.us.kothreat.NavTemplate") ?? .standard
    }
    
    private func formatLogMessage(_ level: LogLevel, _ message: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd#HH:mm:ss"
        dateFormatter.timeZone = .current
        
        let timestamp = dateFormatter.string(from: Date())
        return "\(timestamp) \(target): \(level.rawValue) \(message)"
    }
    
    private func appendLog(_ logLine: String) {
        var logs = userDefaults.stringArray(forKey: logsKey) ?? []
        
        // Add new log line
        logs.append(logLine)
        
        // Keep only the most recent logs if we exceed maxLogLines
        if logs.count > maxLogLines {
            logs = Array(logs.suffix(maxLogLines))
        }
        
        userDefaults.set(logs, forKey: logsKey)
    }
    
    public func info(_ message: String) {
        let logLine = formatLogMessage(.info, message)
        print(logLine)
        appendLog(logLine)
    }
    
    public func debug(_ message: String) {
        #if DEBUG
        let logLine = formatLogMessage(.debug, message)
        print(logLine)
        appendLog(logLine)
        #endif
    }
    
    public func error(_ message: String, error: Error? = nil) {
        var fullMessage = message
        if let error = error {
            fullMessage += " - Error: \(error.localizedDescription)"
        }
        let logLine = formatLogMessage(.error, fullMessage)
        print(logLine)
        appendLog(logLine)
    }
    
    // Helper method to get all logs
    public func getLogs() -> [String] {
        return userDefaults.stringArray(forKey: logsKey) ?? []
    }
    
    // Helper method to clear logs
    public func clearLogs() {
        userDefaults.removeObject(forKey: logsKey)
    }
    
    // New LogList and LogListEntry
    public struct LogListEntry: Identifiable {
        public let id: String
        public let target: String
        public let logs: [String]
        
        public init(target: String, logs: [String]) {
            self.id = target
            self.target = target
            self.logs = logs
        }
    }
    
    public func getLogList() -> [LogListEntry] {
        let logs = getLogs()
        var logList: [LogListEntry] = []
        var currentTarget: String?
        var currentLogs: [String] = []
        
        for log in logs.reversed() {
            // First find the space after timestamp
            if let firstSpaceIndex = log.firstIndex(of: " "),
               // Then find the colon after that space
               let targetEndIndex = log[firstSpaceIndex...].firstIndex(of: ":") {
                // Extract target name (trim the leading space)
                let target = String(log[firstSpaceIndex..<targetEndIndex]).trimmingCharacters(in: .whitespaces)
                
                if currentTarget == nil || currentTarget == target {
                    currentTarget = target
                    currentLogs.append(log)
                } else {
                    logList.append(LogListEntry(target: currentTarget!, logs: currentLogs))
                    currentTarget = target
                    currentLogs = [log]
                }
            }
        }
        
        if let currentTarget = currentTarget {
            logList.append(LogListEntry(target: currentTarget, logs: currentLogs))
        }
        
        return logList
    }
}

@available(iOS 13.0, *)
public class LogManager: ObservableObject {
    @Published public private(set) var logList: [Logger.LogListEntry] = []
    private let logger = Logger.shared
    
    public static let shared = LogManager()
    
    private init() {
        refreshLogs()
    }
    
    public func refreshLogs() {
        logList = logger.getLogList()
    }
    
    public func clearLogs() {
        logger.clearLogs()
        refreshLogs()
    }
} 