import SwiftUI
import NavTemplateShared

struct ActivitiesPage: Page {
    var navigationManager: NavigationManager?
    var widgets: [AnyWidget] { [] }
    
    @StateObject private var activityStack = ActivityStack()
    @State private var consciousState: ActivityType = .wake
    @State private var lastConsciousTime: Date?
    @State private var lastMealTime: Date?
    
    @State private var isLoading = false
    
    @State private var editingItem: ActivityItem?
    @State private var showingEditDialog = false
    @State private var editingItemFrame: CGRect = .zero
    @State private var dialogOffset: CGSize = .zero
    @State private var dialogRect: CGRect = .zero // Track dialog rect
    
    @State private var lastUpdateTime: TimeInterval = 0
    
    private let defaults = UserDefaults(suiteName: "group.us.kothreat.NavTemplate")
    
    @Environment(\.scenePhase) private var scenePhase
    
    private func setupDefaultsObserver() {
        // Observe UserDefaults changes
        NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: defaults,
            queue: .main
        ) { _ in
            if let updateTime = defaults?.double(forKey: "LastActivityUpdate"),
               updateTime > lastUpdateTime {
                lastUpdateTime = updateTime
                updateStateFromStack()
                activityStack.loadActivities()  // Reload data
            }
        }
    }
    
    var body: some View {
        makeMainContent()
            .onAppear {
                setupDefaultsObserver()
            }
    }
    
    private func updateStateFromStack() {
        if let lastConscious = activityStack.getLastConsciousItem() {
            DispatchQueue.main.async {
                self.consciousState = lastConscious.activityType
                self.lastConsciousTime = lastConscious.activityTime
            }
        }
        
        if let lastMeal = activityStack.getLastMealItem() {
            DispatchQueue.main.async {
                self.lastMealTime = lastMeal.activityTime
            }
        }
    }
    
    private func handleActivitySelection(_ activity: ActivityType) {
        let now = Date()
        let newActivity = ActivityItem(type: activity, time: now)
        
        // Push activity and update states
        activityStack.pushActivity(newActivity)
        activityStack.rerenderWidget()
        
        // Update states immediately for UI responsiveness
        switch activity {
        case .sleep, .wake:
            consciousState = activity
            lastConsciousTime = now
            
        case .meal:
            lastMealTime = now
            
        case .exercise:
            break
            
        @unknown default:
            print("Unknown activity type: \(activity.rawValue)")
        }
    }
    
    private func handleEdit(item: ActivityItem, frame: CGRect) {
        editingItem = item
        editingItemFrame = frame

        // Start MyDialog at the item's frame
        dialogRect = frame
        showingEditDialog = true

        // Animate to final position and size (center of screen, 400x300)
        let finalWidth: CGFloat = 400
        let finalHeight: CGFloat = 300
        let screenSize = UIScreen.main.bounds.size
        let finalRect = CGRect(
            x: (screenSize.width - finalWidth) / 2,
            y: (screenSize.height - finalHeight) / 2,
            width: finalWidth,
            height: finalHeight
        )

        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            dialogRect = finalRect
        }
    }
    
    private func dismissDialog() {
        // First animate back to original position and size
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            dialogRect = editingItemFrame
        }
        
        // Remove dialog after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeOut(duration: 0.2)) {
                showingEditDialog = false
            }
        }
    }
    
    private func handleUndo(item: ActivityItem) {
        // First remove the item
        activityStack.removeActivity(item)
        activityStack.rerenderWidget()
        
        // Update states based on what's left in the stack
        DispatchQueue.main.async {
            if item.activityType == .sleep || item.activityType == .wake {
                // Get the latest conscious state after removal
                if let lastConscious = activityStack.getLastConsciousItem() {
                    withAnimation(.easeInOut) {
                        self.consciousState = lastConscious.activityType
                        self.lastConsciousTime = lastConscious.activityTime
                    }
                } else {
                    // No conscious states left, reset to default
                    withAnimation(.easeInOut) {
                        self.consciousState = .wake
                        self.lastConsciousTime = nil
                    }
                }
            }
            
            if item.activityType == .meal {
                // Get the latest meal time after removal
                if let lastMeal = activityStack.getLastMealItem() {
                    self.lastMealTime = lastMeal.activityTime
                } else {
                    // No meals left
                    self.lastMealTime = nil
                }
            }
        }
    }
    
    private func handleActivitySave(originalItem: ActivityItem, newType: ActivityType, newTime: Date) {
        activityStack.updateActivity(originalItem, withType: newType, newTime: newTime)
        activityStack.rerenderWidget()
        
        // Update states if needed
        switch newType {
        case .sleep, .wake:
            // Only update conscious state if this is the latest sleep/wake activity
            if originalItem.id == activityStack.getLastConsciousItem()?.id {
                consciousState = newType
                lastConsciousTime = newTime
            }
        case .meal:
            // Only update meal time if this is the latest meal
            if originalItem.id == activityStack.getLastMealItem()?.id {
                lastMealTime = newTime
            }
        case .exercise:
            break
            
        @unknown default:
            print("Unknown activity type: \(newType.rawValue)")
        }
        
        dismissDialog()
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
                        ActivityListView(
                            activityStack: activityStack,
                            onUndo: handleUndo,
                            onEdit: handleEdit
                        )
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
                
                // Overlay for edit dialog
                if showingEditDialog {
                    Color.black
                        .opacity(0.3)
                        .ignoresSafeArea()
                        .transition(.opacity)
                        .onTapGesture {
                            dismissDialog()
                        }
                    
                    TimeAndActivityPickerDialog(
                        editingItem: editingItem!,
                        onSave: handleActivitySave
                    )
                    .frame(width: dialogRect.width, height: dialogRect.height)
                    .position(x: dialogRect.midX, y: dialogRect.midY)
                    .allowsHitTesting(showingEditDialog)
                }
            }
            .onChange(of: scenePhase) { oldPhase, newPhase in
                if newPhase == .active {
                    isLoading = true
                    print("ActivitiesPage: App entered foreground")
                    activityStack.loadActivities()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        updateStateFromStack()
                        isLoading = false
                    }
                }
            }
            .onAppear {
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