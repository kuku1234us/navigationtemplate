//  ./TaskWidget/TaskWidget.swift

import WidgetKit
import SwiftUI
import AppIntents
import NavTemplateShared

// Add this at the top level of the file, before any struct definitions
// This ensures Logger is initialized before any widget code runs
private let _initializeLogger: Void = {
    Logger.initialize(target: "TaskWidget")
}()

struct Provider: AppIntentTimelineProvider {
    init() {
    }
    
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), tasks: [], configuration: ConfigurationAppIntent())
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        // Load tasks from UserDefaults
        let tasks = TaskModel.loadWidgetTasksFromDefaults() ?? []
        let entry = SimpleEntry(date: Date(), tasks: tasks, configuration: configuration)
        return entry
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        // Load tasks from UserDefaults
        let tasks = TaskModel.loadWidgetTasksFromDefaults() ?? []
        
        // Create entry with current tasks
        let entry = SimpleEntry(date: Date(), tasks: tasks, configuration: configuration)
        
        // Update every 5 minutes or when tasks change
        return Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(300)))
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let tasks: [WidgetTaskItem]
    let configuration: ConfigurationAppIntent
}

struct TaskWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family
    
    private var displayTasks: [WidgetTaskItem] {
        Array(entry.tasks.prefix(16))  // Limit to 16 tasks
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                Spacer()
                
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(displayTasks, id: \.taskId) { task in
                        WidgetTaskItemView(task: task)  // Pass entire WidgetTaskItem
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
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "TaskWidget", intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            TaskWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Tasks")
        .description("View and manage your tasks")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

struct ToggleTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Task Status"
    static var description: LocalizedStringResource = "Toggles a task's completion status"
    
    @Parameter(title: "Task ID")
    var taskId: Int
    
    @Parameter(title: "New Status")
    var newStatus: String
    
    init() {
        self.taskId = 0
        self.newStatus = " "
    }
    
    init(taskId: Int64, newStatus: String) {
        self.taskId = Int(taskId)
        self.newStatus = newStatus
    }
    
    func perform() async throws -> some IntentResult {
        if let task = TaskModel.loadWidgetTasksFromDefaults()?.first(where: { $0.taskId == Int64(taskId) }) {
            TaskModel.pushTaskUpdateToQueue(task, newStatus: newStatus)
        }
        return .result()
    }
}

