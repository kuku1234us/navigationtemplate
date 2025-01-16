import Foundation

// Add Date extension for formatting
public extension Date {
    var yearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: self)
    }
    
    var monthString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: self)
    }
}

public enum CalendarType: String, CaseIterable {
    case day = "Day"
    case week = "Week"
    case month = "Month"
    case year = "Year"
    
    public var icon: String {
        switch self {
        case .day:
            return "calendar.day.timeline.left"
        case .week:
            return "calendar.badge.clock"
        case .month:
            return "calendar"
        case .year:
            return "calendar.badge.exclamationmark"
        }
    }
    
    public var selectedIcon: String {
        switch self {
        case .day:
            return "calendar.day.timeline.left.fill"
        case .week:
            return "calendar.badge.clock.fill"
        case .month:
            return "calendar.circle.fill"
        case .year:
            return "calendar.badge.exclamationmark.fill"
        }
    }
} 

public struct CalendarEvent: Codable, Equatable {
    public let eventTitle: String
    public let startTime: Int  // Unix timestamp in seconds
    public let endTime: Int    // Unix timestamp in seconds
    public let projId: Int64?
    public let reminders: [Int]  // Minutes before event
    public let recurrence: String?  // D, W, M, or null
    public let notes: String?
    public let location: String?  // Address of meeting place
    public let url: String?      // Video conference link
    public let eventId: Int64    // Unix timestamp in seconds, unique identifier
    
    // Add Equatable conformance
    public static func == (lhs: CalendarEvent, rhs: CalendarEvent) -> Bool {
        return lhs.eventId == rhs.eventId &&
               lhs.eventTitle == rhs.eventTitle &&
               lhs.startTime == rhs.startTime &&
               lhs.endTime == rhs.endTime &&
               lhs.projId == rhs.projId &&
               lhs.reminders == rhs.reminders &&
               lhs.recurrence == rhs.recurrence &&
               lhs.notes == rhs.notes &&
               lhs.location == rhs.location &&
               lhs.url == rhs.url
    }
    
    public init(
        eventTitle: String,
        startTime: Int,
        endTime: Int,
        projId: Int64? = nil,
        reminders: [Int] = [],
        recurrence: String? = nil,
        notes: String? = nil,
        location: String? = nil,
        url: String? = nil,
        eventId: Int64
    ) {
        self.eventTitle = eventTitle
        self.startTime = startTime
        self.endTime = endTime
        self.projId = projId
        self.reminders = reminders
        self.recurrence = recurrence
        self.notes = notes
        self.location = location
        self.url = url
        self.eventId = eventId
    }
}

// MARK: - Calendar Model
@MainActor
public class CalendarModel: ObservableObject {
    public static let shared = CalendarModel()
    private let baseDirectory = "Category Notes/Daily"
    
    @Published public private(set) var eventsByYear: [Int: [CalendarEvent]] = [:]
    
    private init() {
        // Initialize empty dictionary
        // Actual loading will happen in setup()
    }
    
    // Setup method to be called after initialization
    @MainActor
    public func setup() async {
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        
        // Load current year and next year
        await loadEventsForYear(currentYear)
        await loadEventsForYear(currentYear + 1)
    }
    
    // MARK: - File Operations
    private func getCalendarFilePath(for year: Int) -> String {
        return "\(baseDirectory)/\(year)/Calendar-\(year).md"
    }
    
    @MainActor
    private func loadEventsForYear(_ year: Int) async {
        guard let vault = ObsidianVaultAccess.shared.vaultURL else { 
            Logger.shared.error("[E015] Failed to access vault while loading calendar events")
            return 
        }
        
        let filePath = getCalendarFilePath(for: year)
        let fileURL = vault.appendingPathComponent(filePath)
        
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            eventsByYear[year] = []
            return
        }
        
        do {
            let fileContent = try String(contentsOf: fileURL, encoding: .utf8)
            let lines = fileContent.components(separatedBy: .newlines)
            
            // Use a dictionary to keep only the latest version of each event
            var latestEvents: [Int64: CalendarEvent] = [:]
            
            // Process each line, keeping only the latest version of each event
            for line in lines where !line.isEmpty {
                if let data = line.data(using: .utf8),
                   let event = try? JSONDecoder().decode(CalendarEvent.self, from: data) {
                    latestEvents[event.eventId] = event  // Later duplicates will override earlier ones
                }
            }
            
            // Convert to array and sort by start time
            eventsByYear[year] = Array(latestEvents.values).sorted { $0.startTime < $1.startTime }
            
        } catch {
            Logger.shared.error("[E016] Error loading events for year \(year): \(error)")
            eventsByYear[year] = []
        }
    }
    
    @MainActor
    public func appendEvent(_ event: CalendarEvent) async throws {
        let startDate = Date(timeIntervalSince1970: TimeInterval(event.startTime))
        let year = Calendar.current.component(.year, from: startDate)
        
        // First remove the event from all years before doing anything else
        for (yearKey, events) in eventsByYear {
            if let index = events.firstIndex(where: { $0.eventId == event.eventId }) {
                var updatedEvents = events
                updatedEvents.remove(at: index)
                eventsByYear[yearKey] = updatedEvents.sorted { $0.startTime < $1.startTime }
            }
        }
        
        guard let vault = ObsidianVaultAccess.shared.vaultURL else {
            Logger.shared.error("[E017] Failed to access vault while appending event")
            throw ObsidianError.vaultNotFound
        }
        
        let filePath = getCalendarFilePath(for: year)
        let fileURL = vault.appendingPathComponent(filePath)
        
        // Create directory if needed
        do {
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
        } catch {
            Logger.shared.error("[E019] Failed to create directory for calendar file: \(error)")
            throw CalendarError.fileOperationFailed
        }
        
        // Create file if it doesn't exist
        if !FileManager.default.fileExists(atPath: fileURL.path) {
            do {
                try "".write(to: fileURL, atomically: true, encoding: .utf8)
            } catch {
                Logger.shared.error("[E020] Failed to create calendar file: \(error)")
                throw CalendarError.fileOperationFailed
            }
        }
        
        // Append the event
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .withoutEscapingSlashes
            let eventJSON = try encoder.encode(event)
            
            let fileHandle = try FileHandle(forWritingTo: fileURL)
            defer { fileHandle.closeFile() }
            fileHandle.seekToEndOfFile()
            fileHandle.write(eventJSON)
            fileHandle.write("\n".data(using: .utf8)!)
        } catch {
            Logger.shared.error("[E021] Failed to append event: \(error)")
            throw CalendarError.fileOperationFailed
        }
        
        // Update counter and check for reconciliation
        let updateCount = UserDefaults.standard.integer(forKey: "CalendarUpdateCount") + 1
        UserDefaults.standard.set(updateCount, forKey: "CalendarUpdateCount")
        
        if updateCount >= 100 {
            do {
                try await reconcileFile(for: year)
                UserDefaults.standard.set(0, forKey: "CalendarUpdateCount")
                await loadEventsForYear(year)  // Reload after reconciliation
            } catch {
                Logger.shared.error("[E022] Failed to reconcile calendar file: \(error)")
                throw CalendarError.reconciliationFailed
            }
        } else {
            // Update in-memory cache
            var eventsForYear = eventsByYear[year] ?? []
            eventsForYear.append(event)
            eventsForYear.sort { $0.startTime < $1.startTime }
            eventsByYear[year] = eventsForYear
        }
        
        objectWillChange.send()
    }
    
    private func reconcileFile(for year: Int) async throws {
        guard let vault = ObsidianVaultAccess.shared.vaultURL else {
            Logger.shared.error("[E018] Failed to access vault during reconciliation")
            throw ObsidianError.vaultNotFound
        }
        
        let filePath = getCalendarFilePath(for: year)
        let fileURL = vault.appendingPathComponent(filePath)
        
        let content = try String(contentsOf: fileURL, encoding: .utf8)
        let lines = content.components(separatedBy: .newlines)
        
        var eventMap: [Int64: String] = [:] // eventId -> JSON string
        
        for line in lines where !line.isEmpty {
            if let data = line.data(using: .utf8),
               let event = try? JSONDecoder().decode(CalendarEvent.self, from: data) {
                eventMap[event.eventId] = line
            }
        }
        
        let reconciledContent = eventMap.values.joined(separator: "\n") + "\n"
        try reconciledContent.write(to: fileURL, atomically: true, encoding: .utf8)
    }
    
    // MARK: - Event Queries
    public func getEventsForDay(date: Date) -> [CalendarEvent] {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let startTimestamp = Int(startOfDay.timeIntervalSince1970)
        let endTimestamp = Int(endOfDay.timeIntervalSince1970)
        
        let events = eventsByYear[year]?.filter { event in
            event.startTime >= startTimestamp && event.startTime < endTimestamp
        } ?? []
        
        return events
    }
    
    public func getEventsForMonth(date: Date) -> [CalendarEvent] {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)
        guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date)),
              let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) else {
            print("Failed to calculate month boundaries")
            return []
        }
        
        let startTimestamp = Int(startOfMonth.timeIntervalSince1970)
        let endTimestamp = Int(endOfMonth.timeIntervalSince1970)

        let eventsList = eventsByYear[year] ?? []
        
        let events = eventsByYear[year]?.filter { event in
            // Event starts before month ends AND ends after month starts
            event.startTime <= endTimestamp && event.endTime >= startTimestamp
        } ?? []
        
        return events
    }
    
    public func getEventsForYear(_ year: Int) -> [CalendarEvent] {
        let events = eventsByYear[year] ?? []
        return events
    }
} 