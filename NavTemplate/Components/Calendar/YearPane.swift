import SwiftUI
import NavTemplateShared

struct YearPane: View, Equatable {
    @Binding var yearDate: Date  // The year being displayed
    @Binding var curDate: Date   // The currently selected date
    @Binding var calendarType: CalendarType
    let onDateChange: (Date) -> Void
    
    private let calendar = Calendar.current

    // Compare the actual values, not the Bindings
    static func == (lhs: Self, rhs: Self) -> Bool {
        let calendar = Calendar.current
        return calendar.isDate(lhs.yearDate, equalTo: rhs.yearDate, toGranularity: .year) &&
        lhs.calendarType == rhs.calendarType
    }    
    
    init(yearDate: Binding<Date>, curDate: Binding<Date>, calendarType: Binding<CalendarType>, onDateChange: @escaping (Date) -> Void) {
        self._yearDate = yearDate
        self._curDate = curDate
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
                        monthDate: months[index],
                        curDate: $curDate,
                        calendarType: $calendarType,
                        onDateChange: onDateChange
                    )
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
                        monthDate: months[index],
                        curDate: $curDate,
                        calendarType: $calendarType,
                        onDateChange: onDateChange
                    )
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
                        monthDate: months[index],
                        curDate: $curDate,
                        calendarType: $calendarType,
                        onDateChange: onDateChange
                    )
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
                        monthDate: months[index],
                        curDate: $curDate,
                        calendarType: $calendarType,
                        onDateChange: onDateChange
                    )
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
        @Binding var curDate: Date   // The currently selected date
        @Binding var calendarType: CalendarType
        let onDateChange: (Date) -> Void
        
        private let calendar = Calendar.current
        @State private var isCurrentMonth: Bool  // Add as member
        @State private var isSelectedMonth: Bool  // Add as member
        
        private let monthFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM"
            return formatter
        }()
        
        @State private var opacity: Double = 0  // Initialize to 0 instead of 1
        
        init(monthDate: Date, curDate: Binding<Date>, calendarType: Binding<CalendarType>, onDateChange: @escaping (Date) -> Void) {
            self.monthDate = monthDate
            self._curDate = curDate
            self._calendarType = calendarType
            self.onDateChange = onDateChange
            
            // Initialize the comparison flags
            let calendar = Calendar.current
            self.isCurrentMonth = calendar.isDate(monthDate, equalTo: Date(), toGranularity: .month)
            self.isSelectedMonth = calendar.isDate(monthDate, equalTo: curDate.wrappedValue, toGranularity: .month)
            
            // No need to set opacity here since @State is already initialized to 0
        }
        
        var body: some View {
            VStack(alignment: .leading, spacing: 4) {
                Text(monthFormatter.string(from: monthDate))
                    .font(.system(size: 20, weight: .black))
                    .foregroundColor(
                        (isCurrentMonth ?
                            Color("PageTitle") : Color("MySecondary"))
                    )
                    .padding(.horizontal, 0)
                    .opacity(opacity)
                
                MiniMonthView(monthDate: monthDate)
                    .opacity(calendarType == .year ? 1 : 0)
                    .animation(.easeInOut(duration: 0.4), value: calendarType)
            }
            .onTapGesture {
                // First update curDate to trigger animations in all cells
                curDate = monthDate   // Update the selected date
                self.isCurrentMonth = calendar.isDate(monthDate, equalTo: Date(), toGranularity: .month)
                self.isSelectedMonth = calendar.isDate(monthDate, equalTo: curDate, toGranularity: .month)
                onDateChange(monthDate)
                
                // Delay calendarType change to allow animations to complete
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                    calendarType = .month
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.014) {
                    opacity = 0  // Hide immediately when selected
                }

            }
            .onChange(of: calendarType) { newType in
                if newType == .year {
                    // Going from .month to .year
                    self.isCurrentMonth = calendar.isDate(monthDate, equalTo: Date(), toGranularity: .month)
                    self.isSelectedMonth = calendar.isDate(monthDate, equalTo: curDate, toGranularity: .month)
                    
                    if isSelectedMonth {
                        // For selected month: show after delay, no animation
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.399) {
                            withAnimation(nil) {
                                opacity = 1
                            }
                        }
                    } else {
                        // For non-selected months: animate showing
                        withAnimation(.easeInOut(duration: 0.4)) {
                            opacity = 1
                        }
                    }
                } else {
                    // Going from .year to .month
                    if isSelectedMonth {
                        // For selected month: hide immediately
                        withAnimation(nil) {
                            opacity = 0
                        }
                    } else {
                        // For non-selected months: animate hiding
                        withAnimation(.easeInOut(duration: 0.4)) {
                            opacity = 0
                        }
                    }
                }
            }
            .onChange(of: curDate) { newDate in
                // Update isSelectedMonth when curDate changes from outside
                self.isSelectedMonth = calendar.isDate(monthDate, equalTo: newDate, toGranularity: .month)
                if isSelectedMonth && calendarType == .month {
                    opacity = 0
                }
            }
        }
    }
} 