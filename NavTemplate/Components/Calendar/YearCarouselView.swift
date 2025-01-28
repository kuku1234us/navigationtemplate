import SwiftUI
import NavTemplateShared

struct YearCarouselView: View {
    @Binding var curDate: Date
    @Binding var calendarType: CalendarType
    let ghostYearPaneRect: CGRect
    
    // Make these static since they're constants
    private static let nPanels = 5
    private static let halfPanels = nPanels / 2
    
    // Store both the dates and the panels
    @State private var yearDates: [Date] = []  // Source of truth for dates
    @State private var curIndex: Int = 0
    
    // For panel sizing and positioning
    private let panelHeight: CGFloat  // Change to let since it won't change
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging: Bool = false
    
    
    init(curDate: Binding<Date>, calendarType: Binding<CalendarType>, ghostYearPaneRect: CGRect) {
        print("Init YearCarouselView currentDate: \(curDate.wrappedValue)")
        
        self._curDate = curDate
        self._calendarType = calendarType
        self.ghostYearPaneRect = ghostYearPaneRect
        self.panelHeight = ghostYearPaneRect.height  // Initialize from ghostYearPaneRect

        // Create initial dates array: -2, -1, 0, +1, +2 years
        let cal = Calendar.current
        let baseYear = Calendar.current.date(from: Calendar.current.dateComponents([.year], from: curDate.wrappedValue))!
        
        var initialDates: [Date] = []
        for offset in -2...2 {
            let newDate = cal.date(byAdding: .year, value: offset, to: baseYear) ?? baseYear
            initialDates.append(offset == 0 ? curDate.wrappedValue : newDate)
        }
        
        // Initialize the @State properties
        _yearDates = State(initialValue: initialDates)
        _curIndex = State(initialValue: Self.nPanels / 2)
    }
    
    private func shiftPanels(direction: Int) {
        // Move the current index
        curIndex = mod((curIndex + direction), Self.nPanels)
        curDate = yearDates[curIndex]  // Update binding directly
        
        let cal = Calendar.current
        var changeIndex = 0
        var newDate = Date()
        let today = Date()

        if (direction == 1) {
            changeIndex = mod((curIndex+Self.halfPanels), Self.nPanels)
            newDate = cal.date(byAdding: .year, value: Self.halfPanels, to: firstOfTheYear(curDate)) ?? curDate
            yearDates[changeIndex] = cal.isDate(newDate, equalTo: today, toGranularity: .year) ? today : newDate
        } else {
            changeIndex = mod((curIndex-Self.halfPanels), Self.nPanels)
            newDate = cal.date(byAdding: .year, value: -1*Self.halfPanels, to: firstOfTheYear(curDate)) ?? curDate
            yearDates[changeIndex] = cal.isDate(newDate, equalTo: today, toGranularity: .year) ? today : newDate
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
        ZStack(alignment: .topLeading) {
            // Create the panels
            ForEach(0..<Self.nPanels, id: \.self) { index in
                let curOffsetY = yOffset(forIndex: index)
                let opacity = max(0, 1 - abs(curOffsetY) / panelHeight * 0.8)
                
                YearPane(
                    yearDate: $yearDates[index],
                    curDate: $curDate,
                    calendarType: $calendarType,
                    onDateChange: { newDate in
                        curDate = newDate
                    }
                )
                .topBottomBorders(width: 0.5, opacity: calendarType == .year ? 0.2 : 0)
                .offset(y: curOffsetY)
                .opacity(opacity)  // Apply opacity based on offset
            }
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: ghostYearPaneRect.height
        )
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
        .onChange(of: curDate) { newDate in
            // Only update if the year actually changed
            let cal = Calendar.current
            if !cal.isDate(yearDates[curIndex], equalTo: newDate, toGranularity: .year) {
                // Create new dates array centered on the new date
                let baseYear = firstOfTheYear(newDate)
                yearDates = (-2...2).map { offset in
                    let date = cal.date(byAdding: .year, value: offset, to: baseYear) ?? baseYear
                    return offset == 0 ? newDate : date
                }
                curIndex = Self.halfPanels  // Reset to center panel
            }
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