// MonthCarouselView.swift

import SwiftUI

struct MonthCarouselView: View {
    @Binding var currentDate: Date  // The "main" date we track externally

    // Make these static since they're constants
    private static let nPanels = 5
    private static let halfPanels = nPanels / 2

    // Store both the dates and the panels
    @State private var monthDates: [Date] = []  // Source of truth for dates
    @State private var panels: [MonthView] = []  // Panels bound to monthDates

    // curIndex tracks which panel is front and center: 2 => panels[2].
    // (0 => 2 left, 4 => 2 right)
    @State private var curIndex: Int = 0

    // For in‐flight drag:
    @State private var dragOffset: CGFloat = 0  // how far the user is dragging horizontally

    @State private var monthViewHeight: CGFloat = 0

    // Add state to track if we're dragging
    @State private var isDragging: Bool = false

    // Initialization
    init(currentDate: Binding<Date>) {
        _currentDate = currentDate
        
        // Create initial panels array
        let cal = Calendar.current
        let baseMonth = firstOfTheMonth(currentDate.wrappedValue)
        
        // Create array of month dates: -2, -1, 0, +1, +2
        var initialDates: [Date] = []
        for offset in -2...2 { 
            let newDate = cal.date(byAdding: .month, value: offset, to: baseMonth) ?? baseMonth
            initialDates.append(offset == 0 ? currentDate.wrappedValue : newDate)
        }
        
        // Initialize the @State properties
        _monthDates = State(initialValue: initialDates)
        _curIndex = State(initialValue: Self.nPanels / 2)
    }

    var body: some View {
        GeometryReader { proxy in
            let panelWidth = proxy.size.width
            
            ZStack(alignment: .topLeading) {
                // Display each of the five panels
                ForEach(0..<Self.nPanels, id: \.self) { i in
                    MonthView(monthDate: $monthDates[i])
                        .frame(width: panelWidth)
                        .overlay(
                            Rectangle()
                                .frame(width: 1)
                                .foregroundColor(Color("MyTertiary").opacity(0.3))
                                .opacity(isDragging ? 1 : 0)
                                .alignmentGuide(.trailing) { _ in 0 },
                            alignment: .trailing
                        )
                        .offset(x: xOffset(forPanel: i, panelWidth: panelWidth))
                        .background(
                            GeometryReader { monthGeo in
                                Color.clear.preference(
                                    key: MonthHeightPreferenceKey.self,
                                    value: monthGeo.size.height
                                )
                            }
                        )
                }
            }
            .frame(height: monthViewHeight)
            .onPreferenceChange(MonthHeightPreferenceKey.self) { h in
                monthViewHeight = h
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
                    .onChanged { value in
                        isDragging = true
                        self.dragOffset = value.translation.width
                    }
                    .onEnded { value in
                        let threshold = panelWidth / 4
                        let translation = value.translation.width
                        if abs(translation) > threshold {
                            let direction = (translation < 0) ? +1 : -1
                            withAnimation(.easeInOut(duration: 0.25)) {
                                shiftPanels(by: direction, panelWidth: panelWidth)
                            }
                            // Hide border after animation completes
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                isDragging = false
                            }
                        } else {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                self.dragOffset = 0
                            }
                            // Hide border after animation completes
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                isDragging = false
                            }
                        }
                    }
            )
        }
        .frame(height: monthViewHeight) // Constrain GeometryReader height
    }

    // MARK: - Panel Offsets

    /// For panel index `i` in 0..4, place it relative to `curIndex`.
    private func xOffset(forPanel i: Int, panelWidth: CGFloat) -> CGFloat {
        var relativeIndex = CGFloat( (mod((i - curIndex + Self.halfPanels), Self.nPanels)) - Self.halfPanels)
        return relativeIndex * panelWidth + dragOffset
    }

    /// Shift the carousel by +1 or -1 (left or right)
    /// Then we reassign the *offscreen* panel so it now represents the newly needed month.
    private func shiftPanels(by direction: Int, panelWidth: CGFloat) {
        // Move the current index
        curIndex = mod ((curIndex + direction), Self.nPanels)

        let cal = Calendar.current

        currentDate = monthDates[curIndex]  // Use monthDates instead of panels

        var changeIndex = 0
        var newDate = Date()
        let today = Date()

        if (direction == 1) {
            changeIndex = mod((curIndex+Self.halfPanels), Self.nPanels)
            newDate = cal.date(byAdding: .month, value: Self.halfPanels, to: firstOfTheMonth(currentDate)) ?? currentDate
            // Check if newDate is in the current month and today
            if cal.isDate(newDate, equalTo: today, toGranularity: .month) {
                monthDates[changeIndex] = today
            } else {
                monthDates[changeIndex] = newDate
            }
        } else {
            changeIndex = mod((curIndex-Self.halfPanels), Self.nPanels)
            newDate = cal.date(byAdding: .month, value: -1*Self.halfPanels, to: firstOfTheMonth(currentDate)) ?? currentDate
            // Check if newDate is in the current month and today
            if cal.isDate(newDate, equalTo: today, toGranularity: .month) {
                monthDates[changeIndex] = today
            } else {
                monthDates[changeIndex] = newDate
            }
        }

        // Reset dragOffset to 0 (center the new position)
        dragOffset = 0
    }

    /// Return the first day of the month for a given date
    private func firstOfTheMonth(_ date: Date) -> Date {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year,.month], from: date)
        return cal.date(from: comps) ?? date
    }

    /// Return the modulo of a number, handling negative values correctly
    /// e.g. mod(-4, 7) returns 3
    private func mod(_ a: Int, _ n: Int) -> Int {
        precondition(n > 0, "modulus must be positive")
        let r = a % n
        return r >= 0 ? r : r + n
    }
}

// MARK: - MonthHeightPreferenceKey

private struct MonthHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}
