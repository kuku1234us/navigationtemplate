import SwiftUI
import NavTemplateShared

struct YearCarouselView: View {
    let curDate: Date
    @Binding var calendarType: CalendarType
    let ghostYearPaneRect: CGRect
    let onDateChange: (Date) -> Void
    
    // Make these static since they're constants
    private static let nPanels = 5
    private static let halfPanels = nPanels / 2
    
    // Store both the dates and the panels
    @State private var yearDates: [Date] = []  // Source of truth for dates
    @State private var curIndex: Int = 0
    
    // For panel sizing and positioning
    @State private var panelHeight: CGFloat = 0
    @State private var middlePanelRect: CGRect = .zero
    
    // For in‐flight drag:
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging: Bool = false
    
    
    init(curDate: Date, calendarType: Binding<CalendarType>, ghostYearPaneRect: CGRect, onDateChange: @escaping (Date) -> Void) {
        self.curDate = curDate
        self._calendarType = calendarType
        self.ghostYearPaneRect = ghostYearPaneRect
        self.onDateChange = onDateChange
        
        panelHeight = 556 // default panel height

        // Create initial dates array: -2, -1, 0, +1, +2 years
        let cal = Calendar.current
        let baseYear = Calendar.current.date(from: Calendar.current.dateComponents([.year], from: curDate))!
        
        var initialDates: [Date] = []
        for offset in -2...2 {
            let newDate = cal.date(byAdding: .year, value: offset, to: baseYear) ?? baseYear
            print("Init Year New date: \(newDate)")
            initialDates.append(offset == 0 ? curDate : newDate)
        }
        
        // Initialize the @State properties
        _yearDates = State(initialValue: initialDates)
        _curIndex = State(initialValue: Self.nPanels / 2)
    }
    
    private func shiftPanels(direction: Int) {
        // Move the current index
        curIndex = mod((curIndex + direction), Self.nPanels)

        let cal = Calendar.current

        let currentDate = yearDates[curIndex]  // Use yearDates instead of panels
        onDateChange(currentDate)  // Notify parent of date change
        print("New currentDate: \(currentDate)")

        var changeIndex = 0
        var newDate = Date()
        let today = Date()

        if (direction == 1) {
            changeIndex = mod((curIndex+Self.halfPanels), Self.nPanels)
            newDate = cal.date(byAdding: .year, value: Self.halfPanels, to: firstOfTheYear(currentDate)) ?? currentDate
            // Check if newDate is in the current year and today
            if cal.isDate(newDate, equalTo: today, toGranularity: .year) {
                yearDates[changeIndex] = today
            } else {
                yearDates[changeIndex] = newDate
            }
        } else {
            changeIndex = mod((curIndex-Self.halfPanels), Self.nPanels)
            newDate = cal.date(byAdding: .year, value: -1*Self.halfPanels, to: firstOfTheYear(currentDate)) ?? currentDate
            // Check if newDate is in the current year and today
            if cal.isDate(newDate, equalTo: today, toGranularity: .year) {
                yearDates[changeIndex] = today
            } else {
                yearDates[changeIndex] = newDate
            }
        }

        // Reset dragOffset to 0 (center the new position)
        dragOffset = 0
    }

    /// Return the first day of the year for a given date
    private func firstOfTheYear(_ date: Date) -> Date {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year], from: date)
        return cal.date(from: comps) ?? date
    }    
    
    private func yOffset(forIndex index: Int) -> CGFloat {
        var relativeIndex = CGFloat((mod((index - curIndex + Self.halfPanels), Self.nPanels)) - Self.halfPanels)
        return relativeIndex * panelHeight + dragOffset
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                // Create the panels
                ForEach(0..<Self.nPanels, id: \.self) { index in
                    let curOffsetY = yOffset(forIndex: index)
                    let opacity = max(0, 1 - abs(curOffsetY) / panelHeight * 0.8)
                    
                    YearPane(
                        yearDate: $yearDates[index],
                        calendarType: $calendarType,
                        onDateChange: onDateChange
                    )
                    .topBottomBorders(width: 0.5, opacity: 0.2)
                    .offset(y: curOffsetY)
                    .opacity(opacity)  // Apply opacity based on offset
                    .background(
                        index == Self.halfPanels ?
                            GeometryReader { geo in
                                Color.clear.preference(
                                    key: YearHeightPreferenceKey.self, 
                                    value: geo.size.height
                                )
                            }
                        : nil
                    )
                }
            }
            .frame(
                maxWidth: .infinity,
                maxHeight: ghostYearPaneRect.height  // Use maxHeight instead of height
            )
            .onPreferenceChange(YearHeightPreferenceKey.self) { h in
                panelHeight = h
                print("New panelHeight onPreference: \(panelHeight)")
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        isDragging = true
                        dragOffset = value.translation.height
                    }
                    .onEnded { value in
                        let threshold = panelHeight / 5
                        let translation = value.translation.height
                        if abs(translation) > threshold {
                            let direction = (translation < 0) ? +1 : -1
                            withAnimation(.easeInOut(duration: 0.25)) {
                                shiftPanels(direction: direction)
                            }
                            // DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                isDragging = false
                            // }
                        } else {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                dragOffset = 0
                            }
                            // DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                isDragging = false
                            // }
                        }
                    }
            )
        }
    }
    
    private func mod(_ a: Int, _ n: Int) -> Int {
        precondition(n > 0, "modulus must be positive")
        let r = a % n
        return r >= 0 ? r : r + n
    }
} 

// MARK: - YearHeightPreferenceKey

private struct YearHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}