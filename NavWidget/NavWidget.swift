//
//  NavWidget.swift
//  NavWidget
//
//  Created by Mac14 on 12/13/24.
//

import WidgetKit
import SwiftUI
import AppIntents
import NavTemplateShared

struct Provider: TimelineProvider {
    // Configuration for timeline generation
    private let numIntervals = 60
    private let minPerInterval = 5
    
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), consciousState: .wake, lastActivityType: nil, lastConsciousTime: nil, lastMealTime: nil, isStaticUpdate: false)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let activityStack = ActivityStack()
        activityStack.loadActivities(isWidget: true)
        let entry = SimpleEntry(
            date: Date(),
            consciousState: activityStack.getLastConsciousItem()?.activityType ?? .wake,
            lastActivityType: activityStack.getTopActivity()?.activityType,
            lastConsciousTime: activityStack.getLastConsciousItem()?.activityTime,
            lastMealTime: activityStack.getLastMealItem()?.activityTime,
            isStaticUpdate: false
        )
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> ()) {
        // 1. Get current data state
        let activityStack = ActivityStack()
        activityStack.loadActivities(isWidget: true)
        
        // Get activity data once
        let consciousState = activityStack.getLastConsciousItem()?.activityType ?? .wake
        let lastActivityType = activityStack.getTopActivity()?.activityType
        let lastConsciousTime = activityStack.getLastConsciousItem()?.activityTime
        let lastMealTime = activityStack.getLastMealItem()?.activityTime
        
        // 2. Generate entries at specified intervals
        let calendar = Calendar.current
        var entries: [SimpleEntry] = []
        let startDate = Date()
        
        // Create entries for specified number of intervals
        for interval in 0..<numIntervals {
            let entryDate = calendar.date(byAdding: .minute, value: interval * minPerInterval, to: startDate)!
            
            let entry = SimpleEntry(
                date: entryDate,
                consciousState: consciousState,
                lastActivityType: lastActivityType,
                lastConsciousTime: lastConsciousTime,
                lastMealTime: lastMealTime,
                isStaticUpdate: interval > 0  // First entry is data-based, rest are static
            )
            entries.append(entry)
        }
        
        // 3. Schedule next timeline refresh after the last entry
        let nextRefreshDate = calendar.date(byAdding: .minute, value: numIntervals * minPerInterval, to: startDate)!
        
        // Create timeline with all entries
        let timeline = Timeline(entries: entries, policy: .after(nextRefreshDate))
        completion(timeline)
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

// Updated Intent implementation
struct AddSleepActivity: AppIntent {
    static var title: LocalizedStringResource = "Add Sleep"
    static var description: LocalizedStringResource = "Records sleep activity"
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult {
        let activityStack = ActivityStack()
        activityStack.loadActivities(isWidget: true)
        activityStack.pushActivity(ActivityItem(type: .sleep))
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
        activityStack.loadActivities(isWidget: true)
        activityStack.pushActivity(ActivityItem(type: .wake))
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
        activityStack.loadActivities(isWidget: true)
        activityStack.pushActivity(ActivityItem(type: .meal))
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
        activityStack.loadActivities(isWidget: true)
        activityStack.pushActivity(ActivityItem(type: .exercise))
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


