import SwiftUI
import NavTemplateShared

struct EventEditor: View {
    // For editing existing event
    let existingEvent: CalendarEvent?
    let defaultDate: Date  // Add defaultDate parameter
    @Binding var isPresented: Bool
    @Binding var showReminderPicker: Bool  // Change to Binding
    let reminderPickerCallback: (@escaping (ReminderType) -> Void) -> Void  // Update type
    let onSave: () -> Void
    
    // State for event properties
    @State private var title: String = ""
    @State private var location: String = ""
    @State private var url: String = ""
    @State private var notes: String = ""
    @FocusState private var focusedField: Field?
    @State private var selectedProject: ProjectMetadata
    @State private var selectedRecurrence: String?
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(3600) // 1 hour later
    @State private var selectedReminders: Set<ReminderType> = []
    @State private var selectedSound: String = DefaultNotificationSound
    
    @StateObject private var projectModel = ProjectModel.shared
    @StateObject private var calendarModel = CalendarModel.shared
    
    @State private var showLocationInput = false
    @State private var showUrlInput = false
    @FocusState private var isLocationFocused: Bool
    @FocusState private var isUrlFocused: Bool
    
    enum Field {
        case title, location, url, notes
    }
    
    // Initialize with optional event
    init(
        event: CalendarEvent? = nil,
        defaultDate: Date = Date(),
        isPresented: Binding<Bool>,
        showReminderPicker: Binding<Bool>,
        reminderPickerCallback: @escaping (@escaping (ReminderType) -> Void) -> Void,  // Add @escaping here too
        onSave: @escaping () -> Void
    ) {
        self.existingEvent = event
        self.defaultDate = defaultDate
        self._isPresented = isPresented
        self._showReminderPicker = showReminderPicker
        self.reminderPickerCallback = reminderPickerCallback
        self.onSave = onSave
        
        // Set initial values
        if let event = event {
            _title = State(initialValue: event.eventTitle)
            _location = State(initialValue: event.location ?? "")
            _url = State(initialValue: event.url ?? "")
            _notes = State(initialValue: event.notes ?? "")
            _startDate = State(initialValue: Date(timeIntervalSince1970: TimeInterval(event.startTime)))
            _endDate = State(initialValue: Date(timeIntervalSince1970: TimeInterval(event.endTime)))
            _selectedRecurrence = State(initialValue: event.recurrence)
            _selectedReminders = State(initialValue: Set(event.reminders))
            
            if let project = ProjectModel.shared.getProject(withId: event.projId ?? 0) {
                _selectedProject = State(initialValue: project)
            } else {
                _selectedProject = State(initialValue: ProjectModel.shared.inboxProject)
            }
        } else {
            // For new events, use defaultDate's date component with current time
            let calendar = Calendar.current
            let now = Date()
            
            // Combine defaultDate's date with current time
            let defaultComponents = calendar.dateComponents([.year, .month, .day], from: defaultDate)
            let timeComponents = calendar.dateComponents([.hour, .minute], from: now)
            var combinedComponents = DateComponents()
            combinedComponents.year = defaultComponents.year
            combinedComponents.month = defaultComponents.month
            combinedComponents.day = defaultComponents.day
            combinedComponents.hour = timeComponents.hour
            combinedComponents.minute = timeComponents.minute
            
            let startTime = calendar.date(from: combinedComponents) ?? now
            _startDate = State(initialValue: startTime)
            _endDate = State(initialValue: startTime.addingTimeInterval(3600)) // 1 hour later
            // For new events, use lastSelectedProjId from settings
            if let lastProject = ProjectModel.shared.getProject(withId: ProjectModel.shared.lastSelectedProjId) {
                _selectedProject = State(initialValue: lastProject)
            } else {
                _selectedProject = State(initialValue: ProjectModel.shared.inboxProject)
            }           
        }
    }
    
    private func handleSave() {
        let eventId: Int64
        if let existingEvent = existingEvent {
            eventId = existingEvent.eventId  // Keep existing ID for updates
        } else {
            // Generate new ID for new events
            // Use milliseconds + random number to avoid collisions
            let timestamp = Int64(Date().timeIntervalSince1970 * 1000)
            let random = Int64.random(in: 0...999)
            eventId = timestamp * 1000 + random
        }
        
        let newEvent = CalendarEvent(
            eventTitle: title.trimmingCharacters(in: .whitespacesAndNewlines),
            startTime: Int(startDate.timeIntervalSince1970),
            endTime: Int(endDate.timeIntervalSince1970),
            projId: selectedProject.projId,
            reminders: Array(selectedReminders),
            recurrence: selectedRecurrence,
            notes: notes.isEmpty ? nil : notes,
            location: location.isEmpty ? nil : location,
            url: url.isEmpty ? nil : url,
            eventId: eventId
        )
        
        Task {
            do {
                // Save event to calendar
                try await calendarModel.appendEvent(newEvent)
                
                // Handle notifications if authorized
                if NotificationModel.shared.isAuthorized {
                    await NotificationModel.shared.scheduleEventReminders(for: newEvent)
                } else {
                    // Request authorization if needed
                    let granted = await NotificationModel.shared.requestAuthorization()
                    if granted {
                        await NotificationModel.shared.scheduleEventReminders(for: newEvent)
                    }
                }
                
                onSave()
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                isPresented = false
            } catch {
                Logger.shared.error("[E024] EventEditor: Failed to save event: \(error)")
            }
        }
    }
    
    // Add onChange handlers for date validation
    private func validateStartDate(_ newDate: Date) {
        if newDate >= endDate {
            // If start time is later than or equal to end time,
            // move end time to 1 hour after new start time
            endDate = newDate.addingTimeInterval(3600)
        }
    }
    
    private func validateEndDate(_ newDate: Date) {
        if newDate <= startDate {
            // If end time is earlier than or equal to start time,
            // move start time to 1 hour before new end time
            startDate = newDate.addingTimeInterval(-3600)
        }
    }
    
    private func addReminder(_ reminder: ReminderType) {
        // First check if we already have a reminder with the same time
        if let existingIndex = selectedReminders.firstIndex(where: { $0.hasSameTime(as: reminder) }) {
            // Remove the existing reminder with same time
            selectedReminders.remove(at: existingIndex)
        }
        
        // Add the new reminder (possibly with different sound)
        selectedReminders.insert(reminder)
    }
    
    var body: some View {
        VStack(spacing: 5) {
            // Title
            ZStack(alignment: .topLeading) {
                if title.isEmpty {
                    Text("Event Title...")
                        .font(.system(size: 16))
                        .foregroundColor(Color("MyTertiary"))
                        .padding(.top, 8)
                        .padding(.leading, 5)
                }
                
                TextEditor(text: $title)
                    .font(.system(size: 16))
                    .foregroundColor(Color("MyPrimary"))
                    .frame(height: 40)
                    .scrollContentBackground(.hidden)
                    .focused($focusedField, equals: .title)
            }
            .padding(.horizontal, 16)
            
            VStack(alignment: .leading, spacing: 10) {
                // Date Pickers with validation
                DatePicker("Start", selection: $startDate)
                    .foregroundColor(Color("MySecondary"))
                    .onChange(of: startDate) { oldValue, newValue in
                        validateStartDate(newValue)
                    }
                
                DatePicker("End", selection: $endDate)
                    .foregroundColor(Color("MySecondary"))
                    .onChange(of: endDate) { oldValue, newValue in
                        validateEndDate(newValue)
                    }
                
                // Reminders List
                ReminderListView(
                    selectedReminders: $selectedReminders,
                    showReminderPicker: $showReminderPicker
                )
                
                // Location Input (conditionally shown)
                if showLocationInput {
                    InputAndIcon(
                        text: $location,
                        placeholder: "Address...",
                        icon: "mappin.circle.fill",
                        backgroundOpacity: 0.1,
                        borderOpacity: 0.1
                    )
                    .focused($isLocationFocused)
                    .onChange(of: location) { oldValue, newValue in
                        if newValue.isEmpty {
                            showLocationInput = false
                        }
                    }
                }
                
                // URL Input (conditionally shown)
                if showUrlInput {
                    InputAndIcon(
                        text: $url,
                        placeholder: "Meeting URL...",
                        icon: "video.circle.fill",
                        backgroundOpacity: 0.1,
                        borderOpacity: 0.1
                    )
                    .focused($isUrlFocused)
                    .onChange(of: url) { oldValue, newValue in
                        if newValue.isEmpty {
                            showUrlInput = false
                        }
                    }
                }
                
                Divider()
                    .background(Color("MyTertiary").opacity(0.3))
                
                // Project Menu, Recurrence Button, Reminder Button, and Save Button
                HStack {
                    ProjectButton(selectedProject: $selectedProject)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    RecurrenceButton(selectedRecurrence: $selectedRecurrence)
                    
                    // Location Toggle Button
                    Button(action: {
                        showLocationInput.toggle()
                        if showLocationInput {
                            isLocationFocused = true
                        }
                    }) {
                        Image(systemName: showLocationInput ? "mappin.circle.fill" : "mappin.circle")
                            .foregroundColor(showLocationInput ? Color("Accent") : Color("MyTertiary"))
                            .font(.system(size: 22))
                            .contentTransition(.symbolEffect(.replace))
                    }
                    .frame(width: 22, height: 22)
                    
                    // URL Toggle Button
                    Button(action: {
                        showUrlInput.toggle()
                        if showUrlInput {
                            isUrlFocused = true
                        }
                    }) {
                        Image(systemName: showUrlInput ? "video.circle.fill" : "video.circle")
                            .foregroundColor(showUrlInput ? Color("Accent") : Color("MyTertiary"))
                            .font(.system(size: 22))
                            .contentTransition(.symbolEffect(.replace))
                    }
                    .frame(width: 22, height: 22)
                    
                    // Reminder Menu
                    Menu {
                        ForEach(ReminderListView.reminderOptions, id: \.self) { minutes in
                            // Check if we already have a reminder at this time
                            if !selectedReminders.contains(where: { $0.minutes == minutes }) {
                                Button {
                                    let reminder = ReminderType(
                                        minutes: minutes, 
                                        sound: DefaultNotificationSound
                                    )
                                    addReminder(reminder)
                                } label: {
                                    HStack {
                                        Text(ReminderListView.formatReminderOption(minutes))
                                    }
                                }
                            }
                        }
                        
                        Button {
                            reminderPickerCallback { reminder in
                                addReminder(reminder)
                            }
                            showReminderPicker = true
                        } label: {
                            Text("Pick Time...")
                        }
                    } label: {
                        Image(systemName: selectedReminders.isEmpty ? "bell" : "bell.fill")
                            .foregroundColor(selectedReminders.isEmpty ? Color("MyTertiary") : Color("Accent"))
                            .font(.system(size: 18))
                    }
                    
                    SaveIconButton(action: handleSave)
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 8)
        }
        .padding(.top, 16)
        .onAppear {
            focusedField = .title
            showLocationInput = !location.isEmpty
            showUrlInput = !url.isEmpty  // Show URL input if there's existing URL
        }
    }
}
