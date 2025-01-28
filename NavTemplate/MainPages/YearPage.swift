import SwiftUI
import NavTemplateShared

struct YearPage: Page {
    var navigationManager: NavigationManager?
    var widgets: [AnyWidget] { [] }

    @State private var eventDisplayLevel: EventDisplayLevel = .byHeader
    @State private var searchText = ""
    @State private var calendarType: CalendarType = .year

    @State var monthRect: CGRect = .zero
    @State var ghostMonthShortTitleRects: [CGRect] = Array(repeating: .zero, count: 12)
    @State var ghostMonthLongTitleRects: [CGRect] = Array(repeating: .zero, count: 12)
    @State var ghostWeekdayRect: CGRect = .zero
    @State var ghostMonthRect: CGRect = .zero
    @State var ghostMiniMonthRects: [MiniMonthRect] = []
    @State var ghostYearPaneRect: CGRect = .zero
    @State var yearRect: CGRect = .zero

    @State var targetYearPaneOffset: CGSize = .zero
    @State var targetYearPaneScale: CGSize = CGSize(width: 1, height: 1)
    @State var targetMonthOffset: CGSize = .zero
    @State var targetMonthScale: CGSize = CGSize(width: 1, height: 1)
    
    @State private var curDate = Date()
    
    @State private var monthCarouselOpacity: Double = 0  // Add opacity state

    func computeTargetYearPaneRect() -> CGRect {
        let curMonthIndex = Calendar.current.component(.month, from: curDate) - 1
        let miniMonthRect = ghostMiniMonthRects[curMonthIndex].miniMonthViewRect  // Make local

        let targetYearPaneWidth = ghostYearPaneRect.width * ghostMonthRect.width / miniMonthRect.width
        let targetYearPaneHeight = ghostYearPaneRect.height * ghostMonthRect.height / miniMonthRect.height

        let edgeDistX = (miniMonthRect.minX-ghostYearPaneRect.minX) * targetYearPaneWidth / ghostYearPaneRect.width
        let edgeDistY = (miniMonthRect.minY-ghostYearPaneRect.minY) * targetYearPaneHeight / ghostYearPaneRect.height

        let safeAreaInsets = UIApplication.shared.windows.first?.safeAreaInsets.top ?? 0

        let targetYearPaneX = ghostMonthRect.minX - edgeDistX
        let targetYearPaneY = ghostMonthRect.minY - edgeDistY 

        return CGRect(x: targetYearPaneX, y: targetYearPaneY, width: targetYearPaneWidth, height: targetYearPaneHeight)
    }

    func computeTargetMiniMonthRect() -> CGRect {
        let curMonthIndex = Calendar.current.component(.month, from: curDate) - 1
        return ghostMiniMonthRects[curMonthIndex].miniMonthViewRect
    }
    
    func makeMainContent() -> AnyView {
        AnyView(
            ZStack(alignment: .topLeading) {
                // Background
                Image("batmanDim")
                    .resizable()
                    .ignoresSafeArea()
                    .overlay(.black.opacity(0.5))

                GhostMonthPage(
                    curDate: $curDate,
                    reportMonthTitleRects: { shortRects, longRects in
                        ghostMonthShortTitleRects = shortRects
                        ghostMonthLongTitleRects = longRects
                    },
                    ghostWeekdayRect: $ghostWeekdayRect,
                    ghostMonthRect: $ghostMonthRect
                )
                .opacity(0)

                GhostYearPage(
                    reportMiniMonthRects: { rects in
                        self.ghostMiniMonthRects = rects
                    },
                    ghostYearPaneRect: $ghostYearPaneRect
                )
                .opacity(0)

                Color.black
                    .opacity(0)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(Rectangle())
                    .allowsHitTesting(true)

                VStack(spacing: 0) {
                    GhostYearHeader()
                        .opacity(0)

                    YearCarouselView(
                        curDate: $curDate,
                        calendarType: $calendarType,
                        ghostYearPaneRect: ghostYearPaneRect
                    )
                    // Need to confirm the dimensions of YearCarouselView for the scale/offset to work
                    .frame(
                        width: ghostYearPaneRect.width,
                        height: ghostYearPaneRect.height
                    )
                    .scaleEffect(targetYearPaneScale)
                    .offset(targetYearPaneOffset)
                    .animation(.easeInOut(duration: 0.4), value: targetYearPaneScale)
                    .animation(.easeInOut(duration: 0.4), value: targetYearPaneOffset)
                    .onChange(of: curDate) { newDate in
                        if calendarType == .month {
                            let targetRect = computeTargetYearPaneRect()
                            targetYearPaneScale = CGSize(
                                width: computeScaleX(from: ghostYearPaneRect, to: targetRect),
                                height: computeScaleY(from: ghostYearPaneRect, to: targetRect)
                            )
                            targetYearPaneOffset = CGSize(
                                width: computeOffsetX(from: ghostYearPaneRect, to: targetRect),
                                height: computeOffsetY(from: ghostYearPaneRect, to: targetRect)
                            )
                        }
                    }
                    .onChange(of: calendarType) { newCalendarType in
                        withAnimation(.easeInOut(duration: 0.4)) {
                            if newCalendarType == .month {
                                let targetRect = computeTargetYearPaneRect()
                                targetYearPaneScale = CGSize(
                                    width: computeScaleX(from: ghostYearPaneRect, to: targetRect),
                                    height: computeScaleY(from: ghostYearPaneRect, to: targetRect)
                                )
                                targetYearPaneOffset = CGSize(
                                    width: computeOffsetX(from: ghostYearPaneRect, to: targetRect),
                                    height: computeOffsetY(from: ghostYearPaneRect, to: targetRect)
                                )
                            } else {
                                targetYearPaneScale = CGSize(width: 1, height: 1)
                                targetYearPaneOffset = CGSize(width: 0, height: 0)
                            }
                        }
                    }
                    .onAppear {
                        // Initialize to year view state
                        targetYearPaneScale = CGSize(width: 1, height: 1)
                        targetYearPaneOffset = CGSize(width: 0, height: 0)
                        
                        // Initialize month carousel to hidden state
                        monthCarouselOpacity = 0
                        targetMonthScale = CGSize(width: 1, height: 1)
                        targetMonthOffset = CGSize(width: 0, height: 0)
                    }                    
                    
                    Spacer()
                }

                // Month Carousel View
                VStack(spacing: 0) {
                    GhostMonthHeader(
                        curDate: curDate,
                        reportMonthTitleRects: { _, _ in },
                        ghostWeekdayRect: .constant(.zero)
                    )
                    .opacity(0)

                    MonthCarouselView(
                        currentDate: $curDate,
                        eventDisplayLevel: $eventDisplayLevel,
                        ghostMonthRect: ghostMonthRect
                    )
                    .opacity(monthCarouselOpacity)
                    .frame(
                        width: ghostMonthRect.width,
                        height: ghostMonthRect.height
                    )
                    .scaleEffect(targetMonthScale)
                    .offset(targetMonthOffset)
                    .onChange(of: calendarType) { newCalendarType in
                        if newCalendarType == .month {
                            // First invisibly position at the new mini month location
                            let targetRect = computeTargetMiniMonthRect()
                            monthCarouselOpacity = 0  // Keep invisible
                            targetMonthScale = CGSize(
                                width: computeScaleX(from: ghostMonthRect, to: targetRect),
                                height: computeScaleY(from: ghostMonthRect, to: targetRect)
                            )
                            targetMonthOffset = CGSize(
                                width: computeOffsetX(from: ghostMonthRect, to: targetRect),
                                height: computeOffsetY(from: ghostMonthRect, to: targetRect)
                            )
                            
                            // Then start the expansion animation after a tiny delay
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                                withAnimation(.easeInOut(duration: 0.4)) {
                                    monthCarouselOpacity = 1
                                    targetMonthScale = CGSize(width: 1, height: 1)
                                    targetMonthOffset = CGSize(width: 0, height: 0)
                                }
                            }
                        } else {
                            // Going from month to year - animate directly
                            withAnimation(.easeInOut(duration: 0.4)) {
                                monthCarouselOpacity = 0
                                let targetRect = computeTargetMiniMonthRect()
                                targetMonthScale = CGSize(
                                    width: computeScaleX(from: ghostMonthRect, to: targetRect),
                                    height: computeScaleY(from: ghostMonthRect, to: targetRect)
                                )
                                targetMonthOffset = CGSize(
                                    width: computeOffsetX(from: ghostMonthRect, to: targetRect),
                                    height: computeOffsetY(from: ghostMonthRect, to: targetRect)
                                )
                            }
                        }
                    }
                }

                VStack(spacing: 0) {
                    CalendarHeaderView(
                        searchText: $searchText,
                        curDate: $curDate,
                        calendarType: $calendarType,
                        eventDisplayLevel: $eventDisplayLevel,
                        ghostMonthShortTitleRects: $ghostMonthShortTitleRects,
                        ghostMonthLongTitleRects: $ghostMonthLongTitleRects,
                        ghostWeekdayRect: $ghostWeekdayRect,
                        ghostMiniMonthRects: ghostMiniMonthRects
                    )
                    .opacity(1)

                    Spacer()
                }

                // Rectangle()
                //     .stroke(Color.red, lineWidth: 1)
                //     .frame(
                //         width: miniMonthRect.width,
                //         height: miniMonthRect.height
                //     )
                //     .offset(
                //         x: miniMonthRect.minX,
                //         y: miniMonthRect.minY
                //     )

                // Rectangle()
                //     .stroke(Color.blue, lineWidth: 1)
                //     .frame(
                //         width: ghostMonthRect.width,
                //         height: ghostMonthRect.height
                //     )
                //     .offset(
                //         x: ghostMonthRect.minX,
                //         y: ghostMonthRect.minY
                //     )

                // Rectangle()
                //     .stroke(Color.green, lineWidth: 1)
                //     .frame(
                //         width: ghostYearPaneRect.width,
                //         height: ghostYearPaneRect.height
                //     )
                //     .offset(
                //         x: ghostYearPaneRect.minX,
                //         y: ghostYearPaneRect.minY
                //     )
                //     .opacity(0.5)
                
                // Toggle button overlay
                // VStack {
                //     Spacer()
                //     Button(action: {
                //         withAnimation(.easeInOut(duration: 0.3)) {
                //             calendarType = calendarType == .month ? .year : .month
                //         }
                //     }) {
                //         Text(calendarType == .month ? "Month" : "Year")
                //             .font(.system(size: 24))
                //             .foregroundColor(Color("PageTitle"))
                //             .frame(width: 60, height: 60)
                //             .background(Color("SideSheetBg").opacity(0.8))
                //             .shadow(radius: 10)
                //     }
                //     .padding(.bottom, 120)
                // }

                // Add BoxOutline on top of everything
                // BoxOutline(miniMonthRects: ghostMiniMonthRects)
                //     .allowsHitTesting(false)  // Let touches pass through
            }
        )
    }
} 