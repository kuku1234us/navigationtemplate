//  ./TaskWidget/TaskWidget.swift

import WidgetKit
import SwiftUI

// Add this struct for widget tasks
struct WidgetTask: Identifiable, Hashable {
    let id: UUID
    let name: String
    let status: String
    let priority: String
    let iconImageName: String  // Store ImageCache name
    
    init(from dictionary: [String: Any]) {
        self.id = UUID()
        self.name = dictionary["name"] as? String ?? ""
        self.status = dictionary["status"] as? String ?? " "
        self.priority = dictionary["priority"] as? String ?? "Normal"
        self.iconImageName = dictionary["iconImageName"] as? String ?? "default_project_icon"
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: WidgetTask, rhs: WidgetTask) -> Bool {
        lhs.id == rhs.id
    }
}

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), tasks: [], configuration: ConfigurationAppIntent())
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        let tasks = loadTasks()
        return SimpleEntry(date: Date(), tasks: tasks, configuration: configuration)
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        let tasks = loadTasks()
        let entry = SimpleEntry(date: Date(), tasks: tasks, configuration: configuration)
        return Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(300)))
    }
    
    private func loadTasks() -> [WidgetTask] {
        // Create UserDefaults with explicit suite name
        if let defaults = UserDefaults(suiteName: "group.us.kothreat.NavTemplate") {
            if let taskDicts = defaults.array(forKey: "WidgetTasks") as? [[String: Any]] {
                return taskDicts.map { WidgetTask(from: $0) }
            }
        }
        return []  // Return empty array if anything fails
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let tasks: [WidgetTask]
    let configuration: ConfigurationAppIntent
}

struct TaskWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family
    
    private var displayTasks: [WidgetTask] {
        Array(entry.tasks.prefix(16))  // Limit to 16 tasks
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                Spacer()
                
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(displayTasks) { task in
                        WidgetTaskItemView(
                            name: task.name,
                            status: task.status,
                            priority: task.priority,
                            iconImageName: task.iconImageName
                        )
                    }
                }
                
                Spacer()
            }
        }
        .containerBackground(for: .widget) {
            Image("TaskBackground")
                .resizable()
                .aspectRatio(contentMode: .fill)
        }
    }
}

struct TaskWidget: Widget {
    let kind: String = "TaskWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            TaskWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Tasks")
        .description("View and manage your tasks")
        .supportedFamilies([
            .systemMedium,
            .systemLarge
        ])
    }
}

