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