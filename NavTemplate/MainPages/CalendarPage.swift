import SwiftUI
import NavTemplateShared

struct CalendarPage: Page {
    // TODO: Replace these placeholders with incoming variables from parent view
    var navigationManager: NavigationManager?
    @State private var ghostMonthShortTitleRect : CGRect = .zero
    @State private var ghostMonthLongTitleRect: CGRect = .zero
    @State private var ghostWeekdayRect: CGRect = .zero
    @State var ghostMiniMonthRects: [MiniMonthRect] = []
    
    @StateObject private var calendarModel = CalendarModel.shared
    @State private var searchText = ""
    @State private var isLoading = true
    @State private var showEventEditor = false
    @State private var eventToEdit: CalendarEvent?
    
    // Calendar specific states
    @State private var curDate = Date()
    @State private var calendarType: CalendarType = .month
    
    // Events state
    @State private var displayedEvents: [CalendarEvent] = []
    @State private var eventDisplayLevel: EventDisplayLevel = .byHeader
    
    // Add arrays for month title rects
    @State private var ghostMonthShortTitleRects: [CGRect] = Array(repeating: .zero, count: 12)
    @State private var ghostMonthLongTitleRects: [CGRect] = Array(repeating: .zero, count: 12)
    
    var widgets: [AnyWidget] {
        return []
    }
    
    private func updateDisplayedEvents() {
        var events: [CalendarEvent]
        switch calendarType {
        case .day:
            events = calendarModel.getEventsForDay(date: curDate)
        case .week:
            events = calendarModel.getEventsForDay(date: curDate)
        case .month:
            events = calendarModel.getEventsForMonth(date: curDate)
        case .year:
            let year = Calendar.current.component(.year, from: curDate)
            events = calendarModel.getEventsForYear(year)
        }
        
        if eventDisplayLevel == .bySelection {
            events = calendarModel.getEventsForDay(date: curDate)
        }
        
        // Apply search filter if needed
        if !searchText.isEmpty {
            displayedEvents = events.filter { event in
                event.eventTitle.localizedCaseInsensitiveContains(searchText) ||
                event.location?.localizedCaseInsensitiveContains(searchText) == true ||
                event.notes?.localizedCaseInsensitiveContains(searchText) == true
            }
        } else {
            displayedEvents = events
        }
        
        // Explicitly trigger UI update
        calendarModel.objectWillChange.send()
    }
    
    private func handleNewEvent() {
        eventToEdit = nil
        showEventEditor = true
    }
    
    private func handleEventTap(_ event: CalendarEvent) {
        eventToEdit = event
        showEventEditor = true
    }
    
    func makeMainContent() -> AnyView {
        AnyView(
            ZStack {
                // Background
                Image("batmanDim")
                    .resizable()
                    .ignoresSafeArea()
                    .overlay(.black.opacity(0.5))
                
                VStack(spacing: 0) {
                    CalendarHeaderView(
                        searchText: $searchText,
                        curDate: $curDate,
                        calendarType: $calendarType,
                        eventDisplayLevel: $eventDisplayLevel,
                        ghostMonthShortTitleRects: ghostMonthShortTitleRects,
                        ghostMonthLongTitleRects: ghostMonthLongTitleRects,
                        ghostWeekdayRect: $ghostWeekdayRect,
                        ghostMiniMonthRects: ghostMiniMonthRects
                    )
                    
                    // Month view
                    MonthCarouselView(
                        currentDate: $curDate,
                        eventDisplayLevel: $eventDisplayLevel
                    )
                    
                    if isLoading {
                        ProgressView()
                            .padding()
                    } else {
                        // Event list with callback
                        EventListView(events: displayedEvents) { event in
                            handleEventTap(event)
                        }
                    }
                    // Spacer()
                }
                .ignoresSafeArea(.keyboard)
                
                // Add Event Button
                AddItemButton(onTap: handleNewEvent)
                
                // Event Editor Bottom Sheet
                if showEventEditor {
                    BottomSheet(isPresented: $showEventEditor) {
                        EventEditor(
                            event: eventToEdit,
                            isPresented: $showEventEditor,
                            onSave: {
                                updateDisplayedEvents()
                            }
                        )
                    }
                    .background(
                        Color.black.opacity(0.1)
                            .ignoresSafeArea()
                            .onTapGesture {
                                showEventEditor = false
                            }
                    )
                }
            }
            .task {
                isLoading = true
                await calendarModel.setup()
                updateDisplayedEvents()
                isLoading = false
            }
            .onChange(of: curDate) { _ in
                updateDisplayedEvents()
            }
            .onChange(of: calendarType) { _ in
                updateDisplayedEvents()
            }
            .onChange(of: searchText) { _ in
                updateDisplayedEvents()
            }
            .onChange(of: calendarModel.eventsByYear) { _ in
                updateDisplayedEvents()
            }
            .onChange(of: eventDisplayLevel) { _ in
                updateDisplayedEvents()
            }
        )
    }
} 