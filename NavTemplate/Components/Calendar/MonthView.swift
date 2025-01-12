import SwiftUI

struct MonthView: View {
    @Binding var currentDate: Date
    let calendar = Calendar.current
    
    // Gesture state
    @GestureState private var dragOffset: CGFloat = 0
    @State private var monthOffset: CGFloat = 0
    
    private func daysInMonth(for date: Date) -> [[Date?]] {
        let monthInterval = calendar.dateInterval(of: .month, for: date)!
        let firstWeekday = calendar.component(.weekday, from: monthInterval.start)
        
        // Calculate days before the first of the month
        var days: [Date?] = Array(repeating: nil, count: firstWeekday - 1)
        
        // Add all days of the month
        let daysInMonth = calendar.range(of: .day, in: .month, for: date)!.count
        for day in 1...daysInMonth {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: monthInterval.start) {
                days.append(date)
            }
        }
        
        // Add remaining days to complete the last week
        while days.count % 7 != 0 {
            days.append(nil)
        }
        
        // Split into weeks
        return stride(from: 0, to: days.count, by: 7).map {
            Array(days[$0..<min($0 + 7, days.count)])
        }
    }
    
    private func changeMonth(by value: Int) {
        if let newDate = calendar.date(byAdding: .month, value: value, to: currentDate) {
            withAnimation {
                currentDate = newDate
            }
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                let weeks = daysInMonth(for: currentDate)
                
                VStack(spacing: 8) {
                    ForEach(weeks.indices, id: \.self) { weekIndex in
                        HStack(spacing: 0) {
                            ForEach(0..<7) { dayIndex in
                                if let date = weeks[weekIndex][dayIndex] {
                                    let day = calendar.component(.day, from: date)
                                    let isToday = calendar.isDate(date, inSameDayAs: Date())
                                    
                                    Text("\(day)")
                                        .font(.system(.body, design: .rounded))
                                        .foregroundColor(isToday ? Color("Accent") : Color("MySecondary"))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .background(
                                            isToday ?
                                            Circle()
                                                .fill(Color("Accent").opacity(0.2))
                                                .frame(width: 32, height: 32)
                                            : nil
                                        )
                                } else {
                                    Text("")
                                        .frame(maxWidth: .infinity)
                                }
                            }
                        }
                    }
                }
                .frame(width: geometry.size.width)
                .offset(x: dragOffset + monthOffset)
            }
        }
        .gesture(
            DragGesture()
                .updating($dragOffset) { value, state, _ in
                    state = value.translation.width
                }
                .onEnded { value in
                    let threshold = UIScreen.main.bounds.width * 0.2
                    if value.translation.width > threshold {
                        changeMonth(by: -1)
                    } else if value.translation.width < -threshold {
                        changeMonth(by: 1)
                    }
                }
        )
        .animation(.spring(duration: 0.3), value: dragOffset)
    }
} 