import SwiftUI

struct ActivitiesPage: Page {
    var navigationManager: NavigationManager?
    var widgets: [AnyWidget] { [] }
    
    @StateObject private var activityStack = ActivityStack()
    @State private var consciousState: ActivityType = .wake
    @State private var lastConsciousTime: Date?
    @State private var lastMealTime: Date?
    
    @State private var isLoading = false
    
    private func updateStateFromStack() {
        print(">>>>> ActivitiesPage: Updating state from stack")
        if let lastConscious = activityStack.getLastConsciousItem() {
            DispatchQueue.main.async {
                self.consciousState = lastConscious.activityType
                self.lastConsciousTime = lastConscious.activityTime
                print(">>>>> ActivitiesPage: Updated conscious state to: \(self.consciousState)")
            }
        }
        
        if let lastMeal = activityStack.getLastMealItem() {
            DispatchQueue.main.async {
                self.lastMealTime = lastMeal.activityTime
                print(">>>>> ActivitiesPage: Updated last meal time")
            }
        }
    }
    
    private func handleActivitySelection(_ activity: ActivityType) {
        print(">>>>> ActivitiesPage: Selected activity: \(activity.rawValue)")
        let now = Date()
        let newActivity = ActivityItem(type: activity, time: now)
        
        // Push activity and update states
        activityStack.pushActivity(newActivity)
        
        // Update states immediately for UI responsiveness
        switch activity {
        case .sleep, .wake:
            consciousState = activity
            lastConsciousTime = now
            print(">>>>> ActivitiesPage: Updated conscious state to: \(activity.rawValue)")
            
        case .meal:
            lastMealTime = now
            print(">>>>> ActivitiesPage: Updated meal time")
            
        case .exercise:
            print(">>>>> ActivitiesPage: Exercise activity recorded")
            break
        }
    }
    
    func makeMainContent() -> AnyView {
        AnyView(
            ZStack {
                Image(consciousState == .sleep ? "NiteBackground" : "DayBackground")                    
                    .resizable()
                    .ignoresSafeArea()
                    .animation(.easeInOut, value: consciousState)
                    .overlay(.black.opacity(0.8))

                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(1.5)
                }

                VStack(spacing: 0) {
                    ActivitiesPageHeader(
                        navigationManager: navigationManager,
                        consciousState: $consciousState,
                        lastConsciousTime: lastConsciousTime,
                        lastMealTime: lastMealTime
                    )
                    
                    HStack(spacing: 0) {
                        ActivityListView(activityStack: activityStack) { item in
                            print(">>>>> ActivitiesPage: Undo requested for: \(item.activityType.rawValue)")
                            // TODO: Implement undo
                        }
                        .frame(maxWidth: .infinity)
                        
                        ActivitiesMenu(
                            onSelect: handleActivitySelection,
                            consciousState: $consciousState
                        )
                        .padding(.horizontal)
                    }
                    .padding(.top)
                    .padding(.leading)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .onAppear {
                print(">>>>> ActivitiesPage: Loading activities")
                isLoading = true
                
                // Load activities and update state
                activityStack.loadActivities()
                
                // Ensure state is updated after activities are loaded
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    updateStateFromStack()
                    isLoading = false
                }
            }
        )
    }
} 