import SwiftUI
import NavTemplateShared

public struct MiniMonthRect {
    let miniMonthShortTitleRect: CGRect  // For "Jan"
    let miniMonthLongTitleRect: CGRect   // For "January"
    let miniMonthViewRect: CGRect
    
    init(
        miniMonthShortTitleRect: CGRect = .zero,
        miniMonthLongTitleRect: CGRect = .zero,
        miniMonthViewRect: CGRect = .zero
    ) {
        self.miniMonthShortTitleRect = miniMonthShortTitleRect
        self.miniMonthLongTitleRect = miniMonthLongTitleRect
        self.miniMonthViewRect = miniMonthViewRect
    }
}

struct CalendarPage: Page {
    var navigationManager: NavigationManager?
    var widgets: [AnyWidget] { [] }

    @State private var eventDisplayLevel: EventDisplayLevel = .byHeader
    @State private var searchText = ""
    @State private var calendarType: CalendarType = .month

    @State var monthRect: CGRect = .zero
    @State var ghostMonthShortTitleRects: [CGRect] = Array(repeating: .zero, count: 12)
    @State var ghostMonthLongTitleRects: [CGRect] = Array(repeating: .zero, count: 12)
    @State var ghostWeekdayRect: CGRect = .zero
    @State var ghostMonthRect: CGRect = .zero
    @State var ghostMiniMonthRects: [MiniMonthRect] = []
    @State var ghostYearPaneRect: CGRect = .zero
    @State var yearRect: CGRect = .zero

    @State var targetYearPaneOffset: CGSize = .zero
    @State var targetYearPaneScale: CGSize = CGSize(width: 1, height: 1)
    @State var targetMonthOffset: CGSize = .zero
    @State var targetMonthScale: CGSize = CGSize(width: 1, height: 1)
    
    @State private var curDate = Date()
    
    @State private var monthCarouselOpacity: Double = 0  // Add opacity state

    @State private var showEventEditor = false
    @State private var eventToEdit: CalendarEvent?
    @State private var displayedEvents: [CalendarEvent] = []
    @State private var isLoading = true

    @StateObject private var calendarModel = CalendarModel.shared

    @State private var eventListOffset: CGFloat = 0
    @State private var eventListOpacity: Double = 1
    @State private var addButtonOffset: CGFloat = 0
    @State private var addButtonOpacity: Double = 1

    @State private var showReminderPicker = false
    @State private var activeReminderCallback: ((ReminderType) -> Void)?

    func computeTargetYearPaneRect() -> CGRect {
        let curMonthIndex = Calendar.current.component(.month, from: curDate) - 1
        let miniMonthRect = ghostMiniMonthRects[curMonthIndex].miniMonthViewRect  // Make local

        let targetYearPaneWidth = ghostYearPaneRect.width * ghostMonthRect.width / miniMonthRect.width
        let targetYearPaneHeight = ghostYearPaneRect.height * ghostMonthRect.height / miniMonthRect.height

        let edgeDistX = (miniMonthRect.minX-ghostYearPaneRect.minX) * targetYearPaneWidth / ghostYearPaneRect.width
        let edgeDistY = (miniMonthRect.minY-ghostYearPaneRect.minY) * targetYearPaneHeight / ghostYearPaneRect.height

        let safeAreaInsets = UIApplication.shared.windows.first?.safeAreaInsets.top ?? 0

        let targetYearPaneX = ghostMonthRect.minX - edgeDistX
        let targetYearPaneY = ghostMonthRect.minY - edgeDistY 

        return CGRect(x: targetYearPaneX, y: targetYearPaneY, width: targetYearPaneWidth, height: targetYearPaneHeight)
    }

    func computeTargetMiniMonthRect() -> CGRect {
        let curMonthIndex = Calendar.current.component(.month, from: curDate) - 1
        return ghostMiniMonthRects[curMonthIndex].miniMonthViewRect
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
            ZStack(alignment: .topLeading) {
                // Background
                Image("batmanDim")
                    .resizable()
                    .ignoresSafeArea()

                GhostMonthPage(
                    curDate: $curDate,
                    reportMonthTitleRects: { shortRects, longRects in
                        print("+++++ reportMonthTitleRects>> shortRects.count: \(shortRects.count)")
                        print("+++++ shortrects[0]: \(shortRects[0])")
                        ghostMonthShortTitleRects = shortRects
                        ghostMonthLongTitleRects = longRects
                    },
                    ghostWeekdayRect: $ghostWeekdayRect,
                    ghostMonthRect: $ghostMonthRect
                )
                .opacity(0)

                GhostYearPage(
                    reportMiniMonthRects: { rects in
                        self.ghostMiniMonthRects = rects
                        
                        // Initialize month view state as soon as rects are available
                        if !rects.isEmpty {
                            let targetRect = computeTargetYearPaneRect()
                            targetYearPaneScale = CGSize(
                                width: computeScaleX(from: ghostYearPaneRect, to: targetRect),
                                height: computeScaleY(from: ghostYearPaneRect, to: targetRect)
                            )
                            targetYearPaneOffset = CGSize(
                                width: computeOffsetX(from: ghostYearPaneRect, to: targetRect),
                                height: computeOffsetY(from: ghostYearPaneRect, to: targetRect)
                            )
                        }
                    },
                    ghostYearPaneRect: $ghostYearPaneRect
                )
                .opacity(0)

                Color.black
                    .opacity(0)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(Rectangle())
                    .allowsHitTesting(true)

                // Actual Year Carousel View
                VStack(spacing: 0) {
                    GhostYearHeader()
                        .opacity(0)

                    YearCarouselView(
                        curDate: $curDate,
                        calendarType: $calendarType,
                        ghostYearPaneRect: ghostYearPaneRect
                    )
                    // Need to confirm the dimensions of YearCarouselView for the scale/offset to work
                    .frame(
                        width: ghostYearPaneRect.width,
                        height: ghostYearPaneRect.height
                    )
                    .scaleEffect(targetYearPaneScale)
                    .offset(targetYearPaneOffset)
                    .animation(.easeInOut(duration: 0.4), value: targetYearPaneScale)
                    .animation(.easeInOut(duration: 0.4), value: targetYearPaneOffset)
                    .onChange(of: curDate) { newDate in
                        if calendarType == .month {
                            let targetRect = computeTargetYearPaneRect()
                            targetYearPaneScale = CGSize(
                                width: computeScaleX(from: ghostYearPaneRect, to: targetRect),
                                height: computeScaleY(from: ghostYearPaneRect, to: targetRect)
                            )
                            targetYearPaneOffset = CGSize(
                                width: computeOffsetX(from: ghostYearPaneRect, to: targetRect),
                                height: computeOffsetY(from: ghostYearPaneRect, to: targetRect)
                            )
                        }
                    }
                    .onChange(of: calendarType) { newCalendarType in
                        withAnimation(.easeInOut(duration: 0.4)) {
                            if newCalendarType == .month {
                                let targetRect = computeTargetYearPaneRect()
                                targetYearPaneScale = CGSize(
                                    width: computeScaleX(from: ghostYearPaneRect, to: targetRect),
                                    height: computeScaleY(from: ghostYearPaneRect, to: targetRect)
                                )
                                targetYearPaneOffset = CGSize(
                                    width: computeOffsetX(from: ghostYearPaneRect, to: targetRect),
                                    height: computeOffsetY(from: ghostYearPaneRect, to: targetRect)
                                )
                            } else {
                                targetYearPaneScale = CGSize(width: 1, height: 1)
                                targetYearPaneOffset = CGSize(width: 0, height: 0)
                            }
                        }
                    }
                    .onAppear {
                        // Initialize to safe default values first
                        targetYearPaneScale = CGSize(width: 1, height: 1)
                        targetYearPaneOffset = CGSize(width: 0, height: 0)
                        monthCarouselOpacity = 1
                        targetMonthScale = CGSize(width: 1, height: 1)
                        targetMonthOffset = CGSize(width: 0, height: 0)
                    }
                    
                    Spacer()
                }

                // ActualMonth Carousel View
                VStack(spacing: 0) {
                    GhostMonthHeader(
                        curDate: curDate,
                        reportMonthTitleRects: { _, _ in },
                        ghostWeekdayRect: .constant(.zero)
                    )
                    .opacity(0)

                    MonthCarouselView(
                        currentDate: $curDate,
                        eventDisplayLevel: $eventDisplayLevel,
                        ghostMonthRect: ghostMonthRect
                    )
                    .opacity(monthCarouselOpacity)
                    .frame(
                        width: ghostMonthRect.width,
                        height: ghostMonthRect.height
                    )
                    .scaleEffect(targetMonthScale)
                    .offset(targetMonthOffset)
                    .onChange(of: calendarType) { newCalendarType in
                        if newCalendarType == .month {
                            // First invisibly position at the new mini month location
                            let targetRect = computeTargetMiniMonthRect()
                            monthCarouselOpacity = 0  // Keep invisible
                            targetMonthScale = CGSize(
                                width: computeScaleX(from: ghostMonthRect, to: targetRect),
                                height: computeScaleY(from: ghostMonthRect, to: targetRect)
                            )
                            targetMonthOffset = CGSize(
                                width: computeOffsetX(from: ghostMonthRect, to: targetRect),
                                height: computeOffsetY(from: ghostMonthRect, to: targetRect)
                            )
                            
                            // Then start the expansion animation after a tiny delay
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                                withAnimation(.easeInOut(duration: 0.4)) {
                                    monthCarouselOpacity = 1
                                    targetMonthScale = CGSize(width: 1, height: 1)
                                    targetMonthOffset = CGSize(width: 0, height: 0)
                                }
                            }
                        } else {
                            // Going from month to year - animate directly
                            withAnimation(.easeInOut(duration: 0.4)) {
                                monthCarouselOpacity = 0
                                let targetRect = computeTargetMiniMonthRect()
                                targetMonthScale = CGSize(
                                    width: computeScaleX(from: ghostMonthRect, to: targetRect),
                                    height: computeScaleY(from: ghostMonthRect, to: targetRect)
                                )
                                targetMonthOffset = CGSize(
                                    width: computeOffsetX(from: ghostMonthRect, to: targetRect),
                                    height: computeOffsetY(from: ghostMonthRect, to: targetRect)
                                )
                            }
                        }
                    }

                    if isLoading {
                        ProgressView()
                            .padding()
                    } else {
                        // Event list with callback
                        EventListView(events: displayedEvents) { event in
                            handleEventTap(event)
                        }
                        .offset(y: eventListOffset)
                        .opacity(eventListOpacity)
                    }                    
                }

                VStack(spacing: 0) {
                    CalendarHeaderView(
                        searchText: $searchText,
                        curDate: $curDate,
                        calendarType: $calendarType,
                        eventDisplayLevel: $eventDisplayLevel,
                        ghostMonthShortTitleRects: $ghostMonthShortTitleRects,
                        ghostMonthLongTitleRects: $ghostMonthLongTitleRects,
                        ghostWeekdayRect: $ghostWeekdayRect,
                        ghostMiniMonthRects: ghostMiniMonthRects
                    )
                    .opacity(1)

                    Spacer()
                }

                // Add Event Editor Bottom Sheet
                // <><><>
                if showEventEditor {
                    BottomSheet(isPresented: $showEventEditor) {
                        EventEditor(
                            event: eventToEdit,
                            defaultDate: curDate,
                            isPresented: $showEventEditor,
                            showReminderPicker: $showReminderPicker,
                            reminderPickerCallback: { callback in
                                self.activeReminderCallback = callback
                            },
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
                
                // Add Event Button
                AddItemButton(onTap: handleNewEvent)
                    .offset(y: addButtonOffset)

                // Add ReminderPicker
                if showReminderPicker {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .onTapGesture {
                            showReminderPicker = false
                        }
                    
                    ReminderPicker(
                        onSave: { reminder in
                            activeReminderCallback?(reminder)
                            showReminderPicker = false
                        },
                        isPresented: $showReminderPicker
                    )
                    .transition(.scale)
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
            .onChange(of: calendarType) { newCalendarType in
                if newCalendarType == .year {
                    // Move EventList and AddButton off screen immediately
                    withAnimation(.easeInOut(duration: 0.4)) {
                        eventListOffset = UIScreen.main.bounds.height
                        eventListOpacity = 0
                        addButtonOffset = UIScreen.main.bounds.height
                        addButtonOpacity = 0
                    }
                } else {
                    // Going to month view
                    // Set display level to show events by month
                    eventDisplayLevel = .byHeader
                    // Update events for the new month
                    updateDisplayedEvents()
                    
                    // Delay bringing back EventList and AddButton
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            eventListOffset = 0
                            eventListOpacity = 1
                        }
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation(.spring(
                            response: 0.4,    // Duration of the animation
                            dampingFraction: 0.8,  // Bounce amount (lower = more bounce)
                            blendDuration: 0
                        )) {
                            addButtonOffset = 0
                            addButtonOpacity = 1
                        }
                    }                    
                }
            }
            .onAppear {
                // Initialize positions based on initial calendarType
                eventListOffset = calendarType == .year ? UIScreen.main.bounds.height : 0
                eventListOpacity = calendarType == .year ? 0 : 1
                addButtonOffset = calendarType == .year ? UIScreen.main.bounds.height : 0
                addButtonOpacity = calendarType == .year ? 0 : 1
                monthCarouselOpacity = 1
                targetMonthScale = CGSize(width: 1, height: 1)
                targetMonthOffset = CGSize(width: 0, height: 0)
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