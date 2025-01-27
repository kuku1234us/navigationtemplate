import SwiftUI

struct MiniMonthView: View, Equatable {
    let monthDate: Date  // First day of the month to display
    
    private let calendar = Calendar.current
    private let numberOfWeekRows = 6
    
    // Help SwiftUI to skip rerendering when the monthDate is the same
    static func == (lhs: MiniMonthView, rhs: MiniMonthView) -> Bool {
        return lhs.monthDate == rhs.monthDate
    }

    private var weeks: [[Date?]] {
        let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: monthDate))!
        let firstWeekday = calendar.component(.weekday, from: firstDay)
        let daysInMonth = calendar.range(of: .day, in: .month, for: firstDay)?.count ?? 0
        
        var days: [Date?] = Array(repeating: nil, count: firstWeekday - 1)
        for day in 1...daysInMonth {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDay) {
                days.append(date)
            }
        }
        
        // Pad to complete 6 rows of weeks
        while days.count < (numberOfWeekRows * 7) {
            days.append(nil)
        }
        
        // Split into weeks
        return stride(from: 0, to: numberOfWeekRows * 7, by: 7).map {
            Array(days[$0..<min($0 + 7, days.count)])
        }
    }
    
    var body: some View {
        VStack(spacing: 2) {
            // Calendar grid
            ForEach(0..<numberOfWeekRows, id: \.self) { weekIndex in
                MonthCell(week: weeks[weekIndex])
            }
        }
        .padding(0)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // .border(.red, width: 1)
    }
    
    // Local component for rendering a week row
    private struct MonthCell: View {
        let week: [Date?]
        
        private let calendar = Calendar.current
        
        var body: some View {
            let today = Date()

            HStack(spacing: 2) {
                ForEach(0..<7, id: \.self) { dayIndex in
                    if let date = week[dayIndex] {
                        Text("\(calendar.component(.day, from: date))")
                            .font(.system(size: 8))
                            .frame(width: 13, height: 13)
                            .foregroundColor(calendar.isDate(date, inSameDayAs: today) ? .black : Color("MySecondary").opacity(0.7))
                            .background(
                                calendar.isDate(date, inSameDayAs: today) ?
                                    Circle().fill(Color("PageTitle")) :
                                    Circle().fill(Color.clear)
                            )
                    } else {
                        Text("")
                            .frame(width: 13, height: 13)
                    }
                }
            }
        }
    }
} 