//  NavWidget.swift

import WidgetKit
import SwiftUI
import AppIntents
import NavTemplateShared

// Add this at the top level of the file, before any struct definitions
// This ensures Logger is initialized before any widget code runs
private let _initializeLogger: Void = {
    Logger.initialize(target: "NavWidget")
}()

struct Provider: TimelineProvider {
    // Configuration for timeline generation
    private let numIntervals = 60
    private let minPerInterval = 5
    
    init() {
    }
    
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), consciousState: .wake, lastActivityType: nil, lastConsciousTime: nil, lastMealTime: nil, isStaticUpdate: false)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let activityStack = ActivityStack()
        activityStack.loadActivitiesFromDefaults()
        
        let entry = SimpleEntry(
            date: Date(),
            consciousState: activityStack.getLastConsciousItem()?.activityType ?? .wake,
            lastActivityType: activityStack.allItems.last?.activityType,
            lastConsciousTime: activityStack.getLastConsciousItem()?.activityTime,
            lastMealTime: activityStack.getLastMealItem()?.activityTime,
            isStaticUpdate: false
        )
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> ()) {
        let activityStack = ActivityStack()
        activityStack.loadActivitiesFromDefaults()
        
        // Get activity data
        let consciousState = activityStack.getLastConsciousItem()?.activityType ?? .wake
        let lastActivityType = activityStack.allItems.last?.activityType
        let lastConsciousTime = activityStack.getLastConsciousItem()?.activityTime
        let lastMealTime = activityStack.getLastMealItem()?.activityTime

        // Check if this is a user-initiated update
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: now)
        let currentMinute = calendar.date(from: components)?.timeIntervalSince1970 ?? 0
        
        let actionDateFormatter = DateFormatter()
        actionDateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        let lastActionTime = activityStack.allItems.last?.activityTime.timeIntervalSince1970 ?? 0
        let isUserInitiated = currentMinute <= lastActionTime
        
        // Generate entries
        var entries: [SimpleEntry] = []
        
        if isUserInitiated {
            // For user-initiated updates, create just 2 entries:
            // 1. Immediate entry
            // 2. Entry for next minute to ensure refresh
            entries.append(SimpleEntry(
                date: now,
                consciousState: consciousState,
                lastActivityType: lastActivityType,
                lastConsciousTime: lastConsciousTime,
                lastMealTime: lastMealTime,
                isStaticUpdate: false
            ))
            
            if let nextMinute = calendar.date(byAdding: .minute, value: 1, to: now) {
                entries.append(SimpleEntry(
                    date: nextMinute,
                    consciousState: consciousState,
                    lastActivityType: lastActivityType,
                    lastConsciousTime: lastConsciousTime,
                    lastMealTime: lastMealTime,
                    isStaticUpdate: true
                ))
            }
                // Force a quick refresh after the 2nd entry time
                let refreshDate = entries.last?.date.addingTimeInterval(1) ?? Date().addingTimeInterval(60)
                print("For user-initiated: next refresh at \(refreshDate)")
                
                completion(
                    Timeline(entries: entries, policy: .after(refreshDate))
                )
                return
        } else {
            // For system updates, create full timeline
            for interval in 0..<numIntervals {
                guard let entryDate = calendar.date(byAdding: .minute, 
                                                  value: interval * minPerInterval, 
                                                  to: now) else { continue }
                
                entries.append(SimpleEntry(
                    date: entryDate,
                    consciousState: consciousState,
                    lastActivityType: lastActivityType,
                    lastConsciousTime: lastConsciousTime,
                    lastMealTime: lastMealTime,
                    isStaticUpdate: interval > 0
                ))
            }
        }
        
        // Always set next refresh to be after the last entry
        let refreshDate = entries.last?.date ?? Date().addingTimeInterval(60)
        
        // Format and print refresh date
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        print("NextRef: \(formatter.string(from: refreshDate)) entries: \(entries.count)")
        
        completion(Timeline(entries: entries, policy: .atEnd))  // Changed to .atEnd
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let consciousState: ActivityType
    let lastActivityType: ActivityType?
    let lastConsciousTime: Date?
    let lastMealTime: Date?
    let isStaticUpdate: Bool
    
    // Pre-computed time indicators
    let consciousTimeDisplay: String
    let mealTimeDisplay: String
    
    init(date: Date, consciousState: ActivityType, lastActivityType: ActivityType?, lastConsciousTime: Date?, lastMealTime: Date?, isStaticUpdate: Bool) {
        self.date = date
        self.consciousState = consciousState
        self.lastActivityType = lastActivityType
        self.lastConsciousTime = lastConsciousTime
        self.lastMealTime = lastMealTime
        self.isStaticUpdate = isStaticUpdate
        
        // Pre-compute time displays
        self.consciousTimeDisplay = Self.formatTimeSince(lastConsciousTime, currentTime: date)
        self.mealTimeDisplay = Self.formatTimeSince(lastMealTime, currentTime: date)
    }
    
    static private func formatTimeSince(_ date: Date?, currentTime: Date) -> String {
        guard let date = date else { return "00:00" }
        let interval = currentTime.timeIntervalSince(date)
        let hours = Int(interval) / 3600
        let minutes = Int(interval) / 60 % 60
        return String(format: "%02d:%02d", hours, minutes)
    }
}

struct NavWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        ZStack {
            Group {
                switch family {
                case .systemSmall:
                    ActivitiesPaneView(
                        layout: .grid,
                        consciousState: entry.consciousState
                    )
                    
                case .systemMedium:
                    HStack() {
                        ActivitiesPaneView(
                            layout: .row,
                            consciousState: entry.consciousState
                        )
                        TimeIndicatorsView(
                            consciousState: entry.consciousState,
                            consciousTimeDisplay: entry.consciousTimeDisplay,
                            mealTimeDisplay: entry.mealTimeDisplay
                        )
                        Spacer()
                    }
                    
                case .systemLarge:
                    VStack {
                        HStack {
                            ActivitiesPaneView(
                                layout: .row,
                                consciousState: entry.consciousState
                            )
                            Spacer()
                            TimeIndicatorsView(
                                consciousState: entry.consciousState,
                                consciousTimeDisplay: entry.consciousTimeDisplay,
                                mealTimeDisplay: entry.mealTimeDisplay
                            )
                            Spacer()
                        }
                        Spacer()
                    }
                    
                case .accessoryCircular:
                    circularLockScreenWidget
                case .accessoryRectangular:
                    rectangularLockScreenWidget
                case .accessoryInline:
                    inlineLockScreenWidget
                case .systemExtraLarge:
                    VStack {
                        ActivitiesPaneView(
                            layout: .row,
                            consciousState: entry.consciousState
                        )
                        Spacer()
                    }
                case .accessoryCorner:
                    circularLockScreenWidget
                @unknown default:
                    ActivitiesPaneView(
                        layout: .grid,
                        consciousState: entry.consciousState
                    )
                }
            }
        }
        .containerBackground(for: .widget) {
            if family == .systemSmall || family == .systemMedium || family == .systemLarge {
                Image(entry.consciousState == .sleep ? "wNiteBackground" : "wDayBackground")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .overlay(.black.opacity(0.7))
            } else {
                AccessoryWidgetBackground()
            }
        }
    }
    
    private var circularLockScreenWidget: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 2) {
                Image(systemName: entry.consciousState == .sleep ? "moon.zzz.fill" : "sun.max.fill")
                    .font(.system(size: 12))
                Text(entry.consciousTimeDisplay)
                    .font(.system(size: 12))
            }
        }
    }
    
    private var rectangularLockScreenWidget: some View {
        VStack(alignment: .leading, spacing: 2) {
            // Top row: Conscious state
            HStack {
                Image(systemName: entry.consciousState == .sleep ? "moon.zzz.fill" : "sun.max.fill")
                    .font(.system(size: 14))
                Text(entry.consciousTimeDisplay)
                    .font(.system(size: 14))
                Spacer()
            }
            
            // Bottom row: Meal time
            HStack {
                Image(systemName: "fork.knife.circle.fill")
                    .font(.system(size: 14))
                Text(entry.mealTimeDisplay)
                    .font(.system(size: 14))
                Spacer()
            }
        }
        .padding(.horizontal, 4)
    }
    
    private var inlineLockScreenWidget: some View {
        // For inline, just show the most relevant time
        HStack {
            Image(systemName: entry.consciousState == .sleep ? "moon.zzz.fill" : "sun.max.fill")
            Text(entry.consciousTimeDisplay)
        }
    }
}

struct NavWidget: Widget {
    let kind: String = "NavWidget"
    
    init() {
        // Force evaluation of the initializer
        _ = _initializeLogger
    }
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            NavWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Activity Status")
        .description("Quick access to activity tracking")
        .supportedFamilies([
            .systemSmall,
            .systemMedium, 
            .systemLarge,
            .accessoryCircular,    // Lock Screen circular
            .accessoryRectangular, // Lock Screen rectangular
            .accessoryInline       // Lock Screen inline text
        ])
    }
}

// Updated Intent implementation with static logger
struct AddSleepActivity: AppIntent {
    static var title: LocalizedStringResource = "Add Sleep"
    static var description: LocalizedStringResource = "Records sleep activity"
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult {
        let activityStack = ActivityStack()
        activityStack.loadActivitiesFromDefaults()
        activityStack.pushActivityToQueue(ActivityItem(type: .sleep))
        activityStack.rerenderWidget()
        activityStack.notifyMainApp()
        return .result()
    }
}

struct AddWakeActivity: AppIntent {
    static var title: LocalizedStringResource = "Add Wake"
    static var description: LocalizedStringResource = "Records wake activity"
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult {
        let activityStack = ActivityStack()
        activityStack.loadActivitiesFromDefaults()
        activityStack.pushActivityToQueue(ActivityItem(type: .wake))
        activityStack.rerenderWidget()
        activityStack.notifyMainApp()
        return .result()
    }
}

struct AddMealActivity: AppIntent {
    static var title: LocalizedStringResource = "Add Meal"
    static var description: LocalizedStringResource = "Records meal activity"
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult {
        let activityStack = ActivityStack()
        activityStack.loadActivitiesFromDefaults()
        activityStack.pushActivityToQueue(ActivityItem(type: .meal))
        activityStack.rerenderWidget()
        activityStack.notifyMainApp()
        return .result()
    }
}

struct AddExerciseActivity: AppIntent {
    static var title: LocalizedStringResource = "Add Exercise"
    static var description: LocalizedStringResource = "Records exercise activity"
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult {
        let activityStack = ActivityStack()
        activityStack.loadActivitiesFromDefaults()
        activityStack.pushActivityToQueue(ActivityItem(type: .exercise))
        activityStack.rerenderWidget()
        activityStack.notifyMainApp()
        return .result()
    }
}

// Add custom button style for tap effect
struct WidgetButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(configuration.isPressed ? Color("Accent") : Color("MySecondary"))
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}


