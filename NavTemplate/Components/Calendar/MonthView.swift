// MonthView.swift

import SwiftUI

/// A single month grid. Always 6 rows x 7 columns (Sun–Sat).
struct MonthView: View {
    // The current date that should be circled and also determines the month being displayed
    @Binding var monthDate: Date 
    
    private var weeks: [[Date?]] {
        // Generate a 6 x 7 matrix of dates (some may be nil if they fall outside the displayed month).
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
                        if let date = weeks[row][col] {
                            DayCell(
                                date: date,
                                monthDate: monthDate,
                                hasEvents: false, // TODO: Add hasEvents parameter
                                onDateTap: { tappedDate in
                                    monthDate = tappedDate
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

    /// Build a 6x7 matrix of Date? for the given month.
    private func generateWeeks(for monthDate: Date) -> [[Date?]] {
        var matrix = Array(repeating: Array(repeating: Date?.none, count: 7), count: 6)

        let cal = Calendar.current

        // 1) First day of this month, e.g. "2023-06-01 00:00"
        let comps = cal.dateComponents([.year, .month], from: monthDate)
        guard let firstOfMonth = cal.date(from: comps) else { return matrix }

        let range = cal.range(of: .day, in: .month, for: firstOfMonth) ?? 1..<1
        let daysInMonth = range.count

        // 2) The weekday of the first day (Sun=1 ... Sat=7 in many locales)
        let firstWeekday = cal.component(.weekday, from: firstOfMonth)  // e.g. "5" if Thu
        // We want Sunday=0..Saturday=6 in our code => shift by 1
        let firstIndex = (firstWeekday - 1) % 7

        var row = 0, col = firstIndex
        // 3) Fill in each day
        for day in 1...daysInMonth {
            let dayDate = cal.date(byAdding: .day, value: day-1, to: firstOfMonth)!
            matrix[row][col] = dayDate
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
    let date: Date
    let monthDate: Date  // This is both the selected date and reference month
    let hasEvents: Bool
    let onDateTap: (Date) -> Void
    
    var body: some View {
        let calendar = Calendar.current
        let isToday = calendar.isDateInToday(date)
        let isSelected = calendar.isDate(date, inSameDayAs: monthDate)
        
        Text("\(calendar.component(.day, from: date))")
            .font(.system(size: 14, weight: isToday ? .black : .regular))
            .foregroundColor(
                isSelected ? (isToday ? .black : Color("MySecondary")) : (isToday ? .blue : Color("MySecondary"))
            )
            .frame(maxWidth: .infinity, minHeight: 30)
            .background(
                Circle()
                    .fill(
                        isSelected ? (isToday ? Color("Accent") : Color("MySecondary").opacity(0.2)) : Color.clear
                    )
                    .frame(width: 24, height: 24)
            )
            .contentShape(Rectangle())  // Make entire area tappable
            .onTapGesture {
                onDateTap(date)
            }
    }
}
