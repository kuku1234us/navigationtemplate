import SwiftUI
import NavTemplateShared

struct CalendarPage: Page {
    var navigationManager: NavigationManager?
    
    @State private var searchText = ""
    @State private var headerFrame: CGRect = .zero
    
    // Calendar specific states
    @State private var curDate = Date()
    @State private var calendarType: CalendarType = .month
    
    var widgets: [AnyWidget] {
        return []  // No widgets for now
    }
    
    func makeMainContent() -> AnyView {
        AnyView(
            ZStack {
                // Background
                Image("batmanDim")
                    .resizable()
                    .ignoresSafeArea()
                    .overlay(.black.opacity(0.5))
                
                VStack(spacing: 0) {
                    CalendarHeaderView(
                        searchText: $searchText,
                        curDate: $curDate,
                        calendarType: $calendarType
                    )
                    .background(
                        GeometryReader { geo in
                            Color.clear
                                .onAppear {
                                    DispatchQueue.main.async {
                                        self.headerFrame = geo.frame(in: .global)
                                    }
                                }
                        }
                    )
                    
                    // Month view
                    MonthCarouselView(currentDate: $curDate)
                    .padding(.horizontal, 12)
                    
                    Spacer()
                }
            }
        )
    }
} 