import SwiftUI
import NavTemplateShared

struct EventEditor: View {
    // For editing existing event
    let existingEvent: CalendarEvent?
    @Binding var isPresented: Bool
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
    @State private var selectedReminders: Set<Int> = []
    
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
    init(event: CalendarEvent? = nil, isPresented: Binding<Bool>, onSave: @escaping () -> Void) {
        self.existingEvent = event
        self._isPresented = isPresented
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
            _selectedProject = State(initialValue: ProjectModel.shared.inboxProject)
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
                try await calendarModel.appendEvent(newEvent)
                onSave()
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                isPresented = false
            } catch {
                print("Failed to save event: \(error)")
            }
        }
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
                // Date Pickers
                DatePicker("Start", selection: $startDate)
                    .foregroundColor(Color("MySecondary"))
                DatePicker("End", selection: $endDate)
                    .foregroundColor(Color("MySecondary"))
                
                // Reminders List
                ReminderListView(selectedReminders: $selectedReminders)
                
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
                            if !selectedReminders.contains(minutes) {
                                Button {
                                    selectedReminders.insert(minutes)
                                } label: {
                                    Text(ReminderListView.formatReminderOption(minutes))
                                }
                            }
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