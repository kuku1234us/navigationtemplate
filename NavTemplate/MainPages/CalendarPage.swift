import SwiftUI
import NavTemplateShared

struct CalendarPage: Page {
    var navigationManager: NavigationManager?
    
    @StateObject private var calendarModel = CalendarModel.shared
    @State private var searchText = ""
    @State private var headerFrame: CGRect = .zero
    @State private var isLoading = true
    @State private var showEventEditor = false
    @State private var eventToEdit: CalendarEvent?
    
    // Calendar specific states
    @State private var curDate = Date()
    @State private var calendarType: CalendarType = .month
    
    // Events state
    @State private var displayedEvents: [CalendarEvent] = []
    
    var widgets: [AnyWidget] {
        return []
    }
    
    private func updateDisplayedEvents() {
        let events: [CalendarEvent]
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
                        calendarType: $calendarType
                    )
                    .background(
                        GeometryReader { geo in
                            Color.clear
                                .onAppear {
                                    DispatchQueue.main.async {
                                        self.headerFrame = geo.frame(in: .global)
                                    }
                                }
                        }
                    )
                    
                    // Month view
                    MonthCarouselView(currentDate: $curDate)
                        .padding(.horizontal, 12)
                    
                    if isLoading {
                        ProgressView()
                            .padding()
                    } else {
                        // Event list with callback
                        EventListView(events: displayedEvents) { event in
                            handleEventTap(event)
                        }
                    }
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
        )
    }
} 