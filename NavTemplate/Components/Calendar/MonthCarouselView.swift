// MonthCarouselView.swift

import SwiftUI
import NavTemplateShared

struct MonthCarouselView: View {
    @Binding var currentDate: Date
    @Binding var eventDisplayLevel: EventDisplayLevel
    let ghostMonthRect: CGRect  // Add this parameter
    
    private static let nPanels = 5
    private static let halfPanels = nPanels / 2
    
    @State private var monthDates: [Date] = []
    @State private var curIndex: Int = 0
    
    // For panel sizing
    private let panelWidth: CGFloat  // Change to let
    
    // For in‐flight drag
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging: Bool = false
    
    init(currentDate: Binding<Date>, eventDisplayLevel: Binding<EventDisplayLevel>, ghostMonthRect: CGRect) {
        _currentDate = currentDate
        _eventDisplayLevel = eventDisplayLevel
        self.ghostMonthRect = ghostMonthRect
        self.panelWidth = ghostMonthRect.width  // Initialize from ghostMonthRect
        
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
        ZStack(alignment: .topLeading) {
            ForEach(0..<Self.nPanels, id: \.self) { i in
                MonthView(monthDate: $monthDates[i], eventDisplayLevel: $eventDisplayLevel, currentDate: $currentDate)
                    .frame(width: panelWidth)
                    .overlay(
                        Rectangle()
                            .frame(width: 1)
                            .foregroundColor(Color("MyTertiary").opacity(0.3))
                            .opacity(isDragging ? 1 : 0)
                            .alignmentGuide(.trailing) { _ in 0 },
                        alignment: .trailing
                    )
                    .offset(x: xOffset(forPanel: i))
            }
        }
        .frame(width: ghostMonthRect.width, height: ghostMonthRect.height)
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
                            eventDisplayLevel = .byHeader
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
        .onChange(of: currentDate) { newDate in
            // Only update if the month actually changed
            let cal = Calendar.current
            if !cal.isDate(monthDates[curIndex], equalTo: newDate, toGranularity: .month) {
                // Create new dates array centered on the new date
                let baseMonth = firstOfTheMonth(newDate)
                monthDates = (-2...2).map { offset in
                    let date = cal.date(byAdding: .month, value: offset, to: baseMonth) ?? baseMonth
                    return offset == 0 ? newDate : date
                }
                curIndex = Self.halfPanels  // Reset to center panel
            }
        }
    }

    // MARK: - Panel Offsets

    /// For panel index `i` in 0..4, place it relative to `curIndex`.
    private func xOffset(forPanel i: Int) -> CGFloat {
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
