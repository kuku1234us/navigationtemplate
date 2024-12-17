import SwiftUI
import AppIntents
import NavTemplateShared

struct ActivitiesPaneView: View {
    let layout: Layout
    let consciousState: ActivityType
    
    enum Layout {
        case grid    // 2x2 for small widget
        case row     // Single row for medium/large
    }
    
    @State private var lastActivityType: ActivityType?
    
    init(layout: Layout = .grid, consciousState: ActivityType) {
        self.layout = layout
        self.consciousState = consciousState
        let activityStack = ActivityStack()
        activityStack.loadActivities(isWidget: true)
        _lastActivityType = State(initialValue: activityStack.getTopActivity()?.activityType)
    }
    
    private func activityButton(_ type: ActivityType) -> some View {
        let intent: any AppIntent
        switch type {
        case .sleep:
            intent = AddSleepActivity()
        case .wake:
            intent = AddWakeActivity()
        case .meal:
            intent = AddMealActivity()
        case .exercise:
            intent = AddExerciseActivity()
        @unknown default:
            intent = AddWakeActivity()
        }
        
        let isLastActivity = type == lastActivityType
        let isDisabled = (type == .sleep && consciousState == .sleep) ||
                        (type == .wake && consciousState == .wake)
        
        return Button(intent: intent) {
            SmallButton(
                icon: type.unfilledIcon,
                iconColor: isLastActivity ? Color("Accent") : Color("MySecondary")
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.5 : 1.0)
    }
    
    var body: some View {
        Group {
            switch layout {
            case .grid:
                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        activityButton(.sleep)
                        activityButton(.wake)
                    }
                    .background(.clear)
                    HStack(spacing: 0) {
                        activityButton(.meal)
                        activityButton(.exercise)
                    }
                    .background(.clear)
                }
                
            case .row:
                HStack(spacing: 5) {
                    activityButton(.sleep)
                    activityButton(.wake)
                    activityButton(.meal)
                    activityButton(.exercise)
                }
                .background(.clear)
            }
        }
        .padding(5)
        .background(Color("SideSheetBg").opacity(0.2))
        .withTransparentCardStyle2()
    }
} 