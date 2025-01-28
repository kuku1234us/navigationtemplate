import SwiftUI
import NavTemplateShared

struct CalendarHeaderView: View {
    @Binding var searchText: String
    @Binding var curDate: Date
    @Binding var calendarType: CalendarType
    // Enable the User to tap on the MonthTitle to switch to .byHeader (meaning by month in this case)
    @Binding var eventDisplayLevel: EventDisplayLevel
    // Received from GhostMonthHeader for the location of the MonthTitle and Weekday letters
    let ghostMonthShortTitleRects: [CGRect]
    let ghostMonthLongTitleRects: [CGRect]
    @Binding var ghostWeekdayRect: CGRect
    let ghostMiniMonthRects: [MiniMonthRect]
    
    @State private var weekdaysOffset: CGFloat = 0
    @State private var searchOffset: CGFloat = 0
    private let weekdaySymbols = Calendar.current.veryShortWeekdaySymbols
    private let calendar = Calendar.current
    
    @State private var chevronOffset: CGFloat = 0
    @State private var chevronOpacity: Double = 1
    private let chevronWidth: CGFloat = 20
    
    @State private var monthTitleScale = CGSize(width: 1, height: 1)
    @State private var monthTitleOffset = CGSize(width: 0, height: 102)
    @State private var isMonthTitleShort = false
    @State private var miniMonthTitleScale = CGSize(width: 1, height: 1)
    @State private var miniMonthTitleOffset = CGSize(width: 0, height: 102)
    
    public static let heightHolderMinHeight: CGFloat = 20
    public static let heightHolderInitHeight: CGFloat = 79
    @State private var heightHolderRectHeight: CGFloat = heightHolderInitHeight
    
    private var currentMonthShortTitleRect: CGRect {
        let currentMonth = calendar.component(.month, from: curDate) - 1 // Convert to 0-based index
        if currentMonth >= 0 && currentMonth < ghostMonthShortTitleRects.count {
            return ghostMonthShortTitleRects[currentMonth]
        }
        return .zero
    }
    
    private var currentMonthLongTitleRect: CGRect {
        let currentMonth = calendar.component(.month, from: curDate) - 1 // Convert to 0-based index
        if currentMonth >= 0 && currentMonth < ghostMonthLongTitleRects.count {
            return ghostMonthLongTitleRects[currentMonth]
        }
        return .zero
    }
    
    private var heightHolderMaxHeight: CGFloat {
        let spacing = CGFloat(8 * 2)  // 8 points spacing * 2
        let bottomPadding = CGFloat(5) // 5 points bottom padding
        return spacing + bottomPadding + currentMonthShortTitleRect.height + ghostWeekdayRect.height
    }
    
    private let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter
    }()
    
    private let shortMonthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter
    }()
    
    private var isCurrentYear: Bool {
        calendar.component(.year, from: curDate) == calendar.component(.year, from: Date())
    }
    
    // State variables for both title rects
    @State private var targetMiniMonthShortTitleRect: CGRect = .zero
    @State private var targetMiniMonthLongTitleRect: CGRect = .zero
    
    // Consolidated helper function to update both title rects
    private func updateTargetMiniMonthTitleRects() {
        // Get current month (1-based)
        let currentMonth = calendar.component(.month, from: curDate) - 1 // Convert to 0-based index
        
        // Update both rects if data is available
        if !ghostMiniMonthRects.isEmpty && currentMonth >= 0 && currentMonth < ghostMiniMonthRects.count {
            let rects = ghostMiniMonthRects[currentMonth]            
            targetMiniMonthShortTitleRect = rects.miniMonthShortTitleRect
            targetMiniMonthLongTitleRect = rects.miniMonthLongTitleRect
        } else {
            targetMiniMonthShortTitleRect = .zero
            targetMiniMonthLongTitleRect = .zero
        }
    }
    
    @State private var transitionStartTime: Date?
    @State private var transitionProgress: CGFloat = 0  // Add this for animation
    
    private func onCalendarTypeChange(_ newType: CalendarType) {
        // Update both rects
        updateTargetMiniMonthTitleRects()
        
        if newType == .year {
            chevronOffset = chevronWidth
            chevronOpacity = 0
            
            searchOffset = UIScreen.main.bounds.width
            weekdaysOffset = -UIScreen.main.bounds.width
            isMonthTitleShort = true
            
            // Calculate transformations
            let sourceRect = CGRect(x: 0, y: 0, width: currentMonthShortTitleRect.width, height: currentMonthShortTitleRect.height)
            monthTitleScale = CGSize(
                width: computeScaleX(from: sourceRect, to: targetMiniMonthShortTitleRect),
                height: computeScaleY(from: sourceRect, to: targetMiniMonthShortTitleRect)
            )
            monthTitleOffset = CGSize(
                width: computeOffsetX(from: sourceRect, to: targetMiniMonthShortTitleRect),
                height: computeOffsetY(from: sourceRect, to: targetMiniMonthShortTitleRect)
            )

            heightHolderRectHeight = CalendarHeaderView.heightHolderMinHeight

        } else {
            chevronOffset = 0
            chevronOpacity = 1
            
            searchOffset = 0
            // weekdaysOffset = -UIScreen.main.bounds.width
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                weekdaysOffset = 0
            }
            isMonthTitleShort = false
            monthTitleScale = CGSize(width: 1, height: 1)
            monthTitleOffset = CGSize(width: 12, height: currentMonthShortTitleRect.origin.y)

            heightHolderRectHeight = heightHolderMaxHeight
            
            // Compute mini Month title transformations
            let sourceRect = CGRect(
                x: targetMiniMonthLongTitleRect.minX, 
                y: targetMiniMonthLongTitleRect.minY, 
                width: targetMiniMonthLongTitleRect.width, 
                height: targetMiniMonthLongTitleRect.height
            )
            let sourceRect2 = CGRect(
                x: 0, 
                y: 0, 
                width: targetMiniMonthLongTitleRect.width, 
                height: targetMiniMonthLongTitleRect.height
            )
            
            miniMonthTitleScale = CGSize(
                width: computeScaleX(from: sourceRect, to: currentMonthLongTitleRect),
                height: computeScaleY(from: sourceRect, to: currentMonthLongTitleRect)
            )
            miniMonthTitleOffset = CGSize(
                width: computeOffsetX(from: sourceRect2, to: currentMonthLongTitleRect),
                height: computeOffsetY(from: sourceRect2, to: currentMonthLongTitleRect)
            )

            // Start transition animation
            transitionStartTime = Date()
            transitionProgress = 0  // Reset progress
            
            // Clear the timestamp after 5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                transitionStartTime = nil
            }
            
            // Reset progress after animation completes
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                transitionProgress = 0
            }
        }
    }

    var body: some View {
        ZStack(alignment: .top) {

            VStack(spacing: 0) {
                // Top row of header
                HStack(spacing: 12) {
                    // Year
                    Button(action: {
                        calendarType = .year
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(Color("MyTertiary"))
                                .frame(width: chevronWidth)
                                .offset(x: chevronOffset)
                                .opacity(chevronOpacity)
                                .animation(.easeInOut(duration: 0.4), value: calendarType)
                            
                            Text(curDate.yearString)
                                .font(calendarType == .year ? .largeTitle : .body)
                                .fontWeight(calendarType == .year ? .black : .regular)
                                .foregroundColor(
                                    calendarType == .year ?
                                        (isCurrentYear ? Color("PageTitle") : Color("MyPrimary")) :
                                        Color("MySecondary")
                                )
                                .offset(x: calendarType == .year ? -chevronWidth : 0)
                                .animation(.easeInOut(duration: 0.4), value: calendarType)
                        }
                    }
                    .buttonStyle(.plain)

                    // Search field
                    TaskSearchField(text: $searchText)
                        .padding(.horizontal, 0)
                        .offset(x: searchOffset)
                        .animation(.easeInOut(duration: 0.4), value: searchOffset)
                }
                .padding(.horizontal, 12)

                // Middle row HeightHolder for the Height of Header
                Rectangle()
                    .frame(height: heightHolderRectHeight)
                    .animation(.easeInOut(duration: 2), value: heightHolderRectHeight)
                    .padding(.horizontal, 12)
                    .foregroundColor(.clear)
            }
            .padding(.top)
            .padding(.horizontal, 0)
            .headerStyle()

            // ZStack - holds MonthTitle and Weekday letters
            ZStack(alignment: .topLeading) {
                // MonthTitle
                HStack {
                    Text(isMonthTitleShort ? shortMonthFormatter.string(from: curDate) : monthFormatter.string(from: curDate))
                        .font(.largeTitle)
                        .fontWeight(.black)
                        .foregroundColor(Color("PageTitle"))
                        .scaleEffect(monthTitleScale)
                        .offset(x: monthTitleOffset.width, y: monthTitleOffset.height)
                        .onTapGesture {
                            eventDisplayLevel = .byHeader
                        }
                    
                    Spacer()
                }
                .animation(.easeInOut(duration: 0.4), value: heightHolderRectHeight)  
                .opacity(self.calendarType == .year ? 0 : 1)
                .animation(
                    .easeInOut(duration: 0.001).delay(0.399),  // Combine the animation and delay
                    value: calendarType
                )

                // Weekday letters
                HStack(spacing: 0) {
                    ForEach(0..<7, id: \.self) { index in
                        Text(weekdaySymbols[index])
                            .font(.footnote)
                            .foregroundColor(Color("MyTertiary"))
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.top, 4)
                .offset(x: weekdaysOffset, y: ghostWeekdayRect.origin.y)
                .animation(.easeInOut(duration: 0.4), value: weekdaysOffset)  

                // Target Mini Month Title Rect
                // Rectangle()
                //     .stroke(Color.red, lineWidth: 1)
                //     .frame(
                //         width: targetMiniMonthLongTitleRect.width,
                //         height: targetMiniMonthLongTitleRect.height
                //     )
                //     .offset(
                //         x: targetMiniMonthLongTitleRect.minX,
                //         y: targetMiniMonthLongTitleRect.minY
                //     )

                // Conditionally render the transition month text
                Group {
                    if let startTime = transitionStartTime,
                       Date().timeIntervalSince(startTime) < 0.4 {
                        Text(transitionProgress < 1.0 ? 
                            shortMonthFormatter.string(from: curDate) :  // First half: show short name
                            monthFormatter.string(from: curDate))        // Second half: show full name
                            .font(.system(size: 20, weight: .black))
                            .foregroundColor(
                                transitionProgress == 0.0 ?
                                (calendar.isDate(curDate, equalTo: Date(), toGranularity: .month) ?
                                    Color("PageTitle") : Color("MySecondary")) :
                                Color("PageTitle")
                            )
                            .opacity(1.0)  // Force full opacity before any animations
                            .scaleEffect(
                                x: 1.0*(1-transitionProgress)+miniMonthTitleScale.width*transitionProgress, 
                                y: 1.0*(1-transitionProgress)+miniMonthTitleScale.height*transitionProgress
                            )
                            .offset(
                                x: targetMiniMonthShortTitleRect.minX*(1-transitionProgress) + miniMonthTitleOffset.width*transitionProgress,
                                y: targetMiniMonthShortTitleRect.minY*(1-transitionProgress) + miniMonthTitleOffset.height*transitionProgress
                            )
                            .animation(.easeInOut(duration: 0.4), value: transitionProgress)  // Animate everything after opacity
                            .onAppear {
                                transitionProgress = 1.0  // Set without animation for opacity
                                withAnimation(.easeInOut(duration: 0.4)) {  // Animate other properties
                                    // This will trigger the animation for scale and offset
                                }
                            }
                    }
                }
            }

        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                heightHolderRectHeight = self.calendarType == .year ? 
                    CalendarHeaderView.heightHolderMinHeight : heightHolderMaxHeight
                monthTitleOffset = CGSize(width: 0, height: currentMonthShortTitleRect.origin.y)
                updateTargetMiniMonthTitleRects()
                onCalendarTypeChange(self.calendarType)
            }
        }
        // .animation(.easeInOut(duration: 0.4), value: heightHolderRectHeight)  
        .onChange(of: calendarType) { newType in
            onCalendarTypeChange(newType)
        }
    }
} 
