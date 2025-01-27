import SwiftUI
import NavTemplateShared

struct MonthPane: View {
    @Binding var curDate: Date
    @Binding var calendarType: CalendarType
    @Binding var monthRect: CGRect
    @Binding var yearRect: CGRect

    @State private var eventDisplayLevel: EventDisplayLevel = .byHeader
    @State private var searchText = ""
    
    var body: some View {
        VStack(spacing: 0) {
            OldMonthHeader(
                searchText: $searchText,
                curDate: $curDate,
                calendarType: $calendarType,
                eventDisplayLevel: $eventDisplayLevel
            )
            .opacity(1)

            ZStack(alignment: .topLeading) {
                MonthCarouselView(
                    currentDate: $curDate,
                    eventDisplayLevel: $eventDisplayLevel
                )
                .padding(.horizontal, 0)
                .frame(width: monthRect.width, height: monthRect.height)
                .clipped()
                .scaleEffect(
                    calendarType == .month ? 
                        CGSize(width: 1, height: 1) : 
                        CGSize(
                            width: computeScaleX(from: monthRect, to: yearRect),
                            height: computeScaleY(from: monthRect, to: yearRect)
                        )
                )
                .offset(x: calendarType == .month ? 0 : computeOffsetX(from: monthRect, to: yearRect), 
                    y: calendarType == .month ? 0 : computeOffsetY(from: monthRect, to: yearRect))
                .overlay(
                    GeometryReader { geo in
                        Color.clear
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    let frame = geo.frame(in: .global)
                                    print("MonthPane - carousel dimensions: \(frame)")
                                    print("MonthPane - expected dimensions: \(monthRect)")
                                    print("MonthPane - offsetX: \(computeOffsetX(from: monthRect, to: yearRect)) \(monthRect.minX) \(yearRect.minX)")
                                    print("MonthPane - offsetY: \(computeOffsetY(from: monthRect, to: yearRect)) \(monthRect.minY) \(yearRect.minY)")
                                }
                            }
                    }
                )
            }
            
            Spacer()
        }
        .ignoresSafeArea(.keyboard)
    }
} 