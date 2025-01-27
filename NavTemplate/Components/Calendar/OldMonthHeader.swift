import SwiftUI
import NavTemplateShared

struct OldMonthHeader: View {
    @Binding var searchText: String
    @Binding var curDate: Date
    @Binding var calendarType: CalendarType
    @Binding var eventDisplayLevel: EventDisplayLevel
    
    private let weekdaySymbols = Calendar.current.veryShortWeekdaySymbols
    
    var body: some View {
        VStack(spacing: 8) {
            // Top row of header
            HStack(spacing: 12) {
                // Year
                Button(action: {
                    // Year selection action
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(Color("MyTertiary"))
                        Text(curDate.yearString)
                            .foregroundColor(Color("MySecondary"))
                    }
                }
                .buttonStyle(.plain)

                // Search field
                TaskSearchField(text: $searchText)
                    .padding(.horizontal, 0)
            }

            // Middle row of header
            HStack {
                Text(curDate.monthString)
                    .font(.largeTitle)
                    .fontWeight(.black)
                    .foregroundColor(Color("PageTitle"))
                
                Spacer()
                
                // Calendar type picker
                HStack(spacing: 8) {
                    ForEach(CalendarType.allCases, id: \.self) { type in
                        Button(action: {
                            calendarType = type
                        }) {
                            Image(systemName: calendarType == type ? type.selectedIcon : type.icon)
                                .foregroundColor(calendarType == type ? Color("Accent") : Color("MyTertiary"))
                                .contentTransition(.symbolEffect(.replace))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            // Bottom row - weekday letters
            HStack(spacing: 0) {
                ForEach(0..<7, id: \.self) { index in
                    Text(weekdaySymbols[index])
                        .font(.footnote)
                        .foregroundColor(Color("MyTertiary"))
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.top, 4)
        }
        .withSafeAreaTop()
        .padding(.top)
        .padding(.horizontal, 12)
        .padding(.bottom, 5)
        // .backgroundBlur(radius: 10, opaque: true)
        .background(
            MeshGradient(
                width: 3, height: 3,
                points: [
                    [0.0,0.0], [0.5,0.0], [1.0,0.0],
                    [0.0,0.5], [0.5,0.5], [1.0,0.5],
                    [0.0,1.0], [0.5,1.0], [1.0,1.0]
                ],
                colors: [
                    Color("Background"),Color("Background"),.black,
                    .blue,Color("Background"),Color("Background"),
                    .blue,.blue,Color("Background"),                    
                ]
            )
            .opacity(0.0)
        )
    }
} 