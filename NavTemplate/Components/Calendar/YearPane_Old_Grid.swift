import SwiftUI
import NavTemplateShared

struct YearPane_Old_Grid: View {
    @Binding var yearDate: Date
    @Binding var curDate: Date
    @Binding var calendarType: CalendarType
    
    private let calendar = Calendar.current
    
    private var months: [Date] {
        let year = calendar.component(.year, from: yearDate)
        return (1...12).compactMap { month in
            calendar.date(from: DateComponents(year: year, month: month, day: 1))
        }
    }
    
    var body: some View {
        let columns = Array(repeating: GridItem(.flexible()), count: 3)
        
        LazyVGrid(columns: columns, spacing: 20) {
            ForEach(months, id: \.self) { monthDate in
                MiniMonthCell(
                    monthDate: monthDate,
                    curDate: $curDate
                )
                .onTapGesture {
                    curDate = monthDate  // Set to first day of month
                    calendarType = .month
                }
            }
        }
        .padding()
    }

    private struct MiniMonthCell: View {
        let monthDate: Date
        @Binding var curDate: Date
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
                        calendar.isDate(monthDate, equalTo: curDate, toGranularity: .month) ?
                            Color("PageTitle") : Color("MySecondary")
                    )
                    .padding(.horizontal, 4)
                
                MiniMonthView(monthDate: monthDate)
            }
        }
    }
} 