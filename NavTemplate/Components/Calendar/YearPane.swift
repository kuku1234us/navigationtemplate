import SwiftUI
import NavTemplateShared

struct YearPane: View, Equatable {
    @Binding var yearDate: Date
    @Binding var calendarType: CalendarType
    let onDateChange: (Date) -> Void
    
    private let calendar = Calendar.current

    // Compare the actual values, not the Bindings
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.yearDate == rhs.yearDate &&
        lhs.calendarType == rhs.calendarType
    }    
    
    init(yearDate: Binding<Date>, calendarType: Binding<CalendarType>, onDateChange: @escaping (Date) -> Void) {
        self._yearDate = yearDate
        self._calendarType = calendarType
        self.onDateChange = onDateChange
    }
    
    private var months: [Date] {
        let year = calendar.component(.year, from: yearDate)
        return (1...12).compactMap { month in
            calendar.date(from: DateComponents(year: year, month: month, day: 1))
        }
    }
    
    var body: some View {
        let _ = print("\(Int.random(in: 10...99)) YearPane body re-computed for year:", calendar.component(.year, from: yearDate))

        VStack(alignment: .leading, spacing: 20) {
            // First row: January - March
            HStack {
                ForEach(0..<3) { index in
                    MiniMonthCell(
                        monthDate: months[index]
                    )
                    .onTapGesture {
                        onDateChange(months[index])
                        calendarType = .month
                    }
                    if index < 2 {
                        Spacer()
                    }
                }
            }
            .fixedSize(horizontal: false, vertical: true)  // Allow horizontal flex but fix height to content
            
            // Second row: April - June
            HStack {
                ForEach(3..<6) { index in
                    MiniMonthCell(
                        monthDate: months[index]
                    )
                    .onTapGesture {
                        onDateChange(months[index])
                        calendarType = .month
                    }
                    if index < 5 {
                        Spacer()
                    }
                }
            }
            .fixedSize(horizontal: false, vertical: true)
            
            // Third row: July - September
            HStack {
                ForEach(6..<9) { index in
                    MiniMonthCell(
                        monthDate: months[index]
                    )
                    .onTapGesture {
                        onDateChange(months[index])
                        calendarType = .month
                    }
                    if index < 8 {
                        Spacer()
                    }
                }
            }
            .fixedSize(horizontal: false, vertical: true)
            
            // Fourth row: October - December
            HStack {
                ForEach(9..<12) { index in
                    MiniMonthCell(
                        monthDate: months[index]
                    )
                    .onTapGesture {
                        onDateChange(months[index])
                        calendarType = .month
                    }
                    if index < 11 {
                        Spacer()
                    }
                }
            }
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
    }

    private struct MiniMonthCell: View {
        let monthDate: Date

        private let calendar = Calendar.current
        
        private let monthFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM"
            return formatter
        }()
        
        var body: some View {
            VStack(alignment: .leading, spacing: 4) {
                Text(monthFormatter.string(from: monthDate))
                    .font(.system(size: 20, weight: .black))
                    .foregroundColor(
                        calendar.isDate(monthDate, equalTo: Date(), toGranularity: .month) ?
                            Color("PageTitle") : Color("MySecondary")
                    )
                    .padding(.horizontal, 0)
                
                MiniMonthView(monthDate: monthDate)
            }
        }
    }
} 