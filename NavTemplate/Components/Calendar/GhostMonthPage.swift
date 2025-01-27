import SwiftUI
import NavTemplateShared

struct GhostMonthPage: View {
    @Binding var curDate: Date
    let reportMonthTitleRects: ([CGRect], [CGRect]) -> Void  // Reports (shortRects, longRects)
    @Binding var ghostWeekdayRect: CGRect
    @Binding var ghostMonthRect: CGRect
    
    var body: some View {
        VStack(spacing: 0) {
            GhostMonthHeader(
                curDate: curDate,
                reportMonthTitleRects: reportMonthTitleRects,  // Pass through the callback
                ghostWeekdayRect: $ghostWeekdayRect
            )

            // Month view with GeometryReader to track its natural position
            // MonthCarouselView(
            //     currentDate: $curDate,
            //     eventDisplayLevel: $eventDisplayLevel
            // )
            // .padding(.horizontal, 12)
            GhostMonthView()
                .background(
                    GeometryReader { geo in
                        Color.clear
                            .onAppear {
                                DispatchQueue.main.async {
                                    let frame = geo.frame(in: .global)
                                    let screenWidth = UIScreen.main.bounds.width
                                    self.ghostMonthRect = CGRect(
                                        x: 0,
                                        y: frame.origin.y,
                                        width: screenWidth,
                                        height: frame.height
                                    )
                                }
                            }
                    }
                )

            Spacer()
        }
        .ignoresSafeArea(.keyboard)
    }
} 