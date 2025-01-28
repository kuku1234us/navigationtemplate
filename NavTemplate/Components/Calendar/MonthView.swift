// MonthView.swift

import SwiftUI
import NavTemplateShared

// Bundle date and hasEvents together
private struct DayCellData {
    let date: Date
    let hasEvents: Bool
}

/// A single month grid. Always 6 rows x 7 columns (Sun–Sat).
struct MonthView: View, Equatable {
    // The current date that should be circled and also determines the month being displayed
    @Binding var monthDate: Date 
    @Binding var eventDisplayLevel: EventDisplayLevel
    @Binding var currentDate: Date
    @StateObject private var calendarModel = CalendarModel.shared

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.monthDate == rhs.monthDate
    }
    
    private var weeks: [[DayCellData?]] {
        // Generate a 6 x 7 matrix of DayCellData (some may be nil if they fall outside the displayed month).
        generateWeeks(for: monthDate)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Text(monthNameString(from: monthDate))
            //     .font(.headline)            
            // The 6 rows of days
            ForEach(0..<6, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<7, id: \.self) { col in
                        if let cellData = weeks[row][col] {
                            DayCell(
                                cellData: cellData,
                                monthDate: monthDate,
                                onDateTap: { tappedDate in
                                    monthDate = tappedDate
                                    currentDate = tappedDate
                                    eventDisplayLevel = .bySelection
                                }
                            )
                        } else {
                            Color.clear
                                .frame(maxWidth: .infinity, minHeight: 30)  // Match cell spacing
                        }
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    /// Return localized month name + year, e.g. "June 2023"
    private func monthNameString(from date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "LLLL yyyy"  // e.g. "June 2023"
        return fmt.string(from: date)
    }

    /// Return "Sun", "Mon", "Tue", etc.
    private func shortWeekdaySymbol(_ col: Int) -> String {
        let symbols = ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"]
        return symbols[col]
    }

    /// Return the day-of-month as a string, e.g. "7"
    private func dayString(from date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "d"
        return fmt.string(from: date)
    }

    /// Whether `date` is in the same calendar month as `reference`.
    private func isSameMonth(_ date: Date, as reference: Date) -> Bool {
        let cal = Calendar.current
        return cal.component(.month, from: date) == cal.component(.month, from: reference)
            && cal.component(.year, from: date) == cal.component(.year, from: reference)
    }

    /// Build a 6x7 matrix of DayCellData? for the given month.
    private func generateWeeks(for monthDate: Date) -> [[DayCellData?]] {
        var matrix = Array(repeating: Array(repeating: DayCellData?.none, count: 7), count: 6)
        
        let cal = Calendar.current
        
        // 1) First day of this month
        let comps = cal.dateComponents([.year, .month], from: monthDate)
        guard let firstOfMonth = cal.date(from: comps) else { return matrix }
        
        let range = cal.range(of: .day, in: .month, for: firstOfMonth) ?? 1..<1
        let daysInMonth = range.count
        
        let firstWeekday = cal.component(.weekday, from: firstOfMonth)
        let firstIndex = (firstWeekday - 1) % 7
        
        var row = 0, col = firstIndex
        for day in 1...daysInMonth {
            let dayDate = cal.date(byAdding: .day, value: day-1, to: firstOfMonth)!
            
            // Check for events on this day
            let hasEvents = !calendarModel.getEventsForDay(date: dayDate).isEmpty
            
            matrix[row][col] = DayCellData(date: dayDate, hasEvents: hasEvents)
            
            col += 1
            if col > 6 {
                col = 0
                row += 1
                if row > 5 { break }
            }
        }
        return matrix
    }

    /// Add helper function to check if two dates are the same
    private func isSameDate(_ date1: Date, _ date2: Date) -> Bool {
        let cal = Calendar.current
        return cal.isDate(date1, inSameDayAs: date2)
    }

    /// Add helper function to check if a date is today
    private func isToday(_ date: Date) -> Bool {
        let cal = Calendar.current
        return cal.isDateInToday(date)
    }
}

private struct DayCell: View {
    let cellData: DayCellData
    let monthDate: Date
    let onDateTap: (Date) -> Void
    
    var body: some View {
        let calendar = Calendar.current
        let isToday = calendar.isDateInToday(cellData.date)
        let isSelected = calendar.isDate(cellData.date, inSameDayAs: monthDate)
        
        ZStack {
            // Background circle
            Circle()
                .fill(
                    isSelected ? (isToday ? Color("PageTitle") : Color("Accent")) : Color.clear
                )
                .frame(width: 24, height: 24)
            
            // Date text centered in cell
            Text("\(calendar.component(.day, from: cellData.date))")
                .font(.system(size: 14, weight: isToday ? .black : (cellData.hasEvents ? .bold : .regular)))
                .foregroundColor(
                    isSelected ? (isToday ? .black : .black) : (isToday ? Color("PageTitle") : (cellData.hasEvents ? Color("MyPrimary") : Color("MyTertiary")))
                )
            
            // Event indicator dot at bottom
            if cellData.hasEvents {
                Circle()
                    .fill(Color("MyPrimary"))
                    .frame(width: 6, height: 6)
                    .offset(y: 18)  // Position below the date
            }
        }
        .frame(maxWidth: .infinity, minHeight: 35)
        .contentShape(Rectangle())
        .onTapGesture {
            onDateTap(cellData.date)
        }
    }
}
