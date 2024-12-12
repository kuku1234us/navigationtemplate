import SwiftUI

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
        
        // Update states immediately for UI responsiveness
        switch activity {
        case .sleep, .wake:
            consciousState = activity
            lastConsciousTime = now
            
        case .meal:
            lastMealTime = now
            
        case .exercise:
            break
        }
    }
    
    private func handleEdit(item: ActivityItem, frame: CGRect) {
        editingItem = item
        editingItemFrame = frame

        // Start MyDialog at the item's frame
        dialogRect = frame
        print("Dialog rect: \(dialogRect)")
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

        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            dialogRect = finalRect
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
                        ActivityListView(
                            activityStack: activityStack,
                            onUndo: { item in
                                print("Undo activity: \(item.activityType.rawValue)")
                            },
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
                    
                    TimeAndActivityPickerDialog()
                        .frame(width: dialogRect.width, height: dialogRect.height)
                        .position(x: dialogRect.midX, y: dialogRect.midY)                    
                    // (
                        // initialActivity: editingItem?.activityType ?? .sleep,
                        // initialTime: editingItem?.activityTime ?? Date(),
                        // onSave: { activity, time in
                        //     // TODO: Handle edit
                        //     withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        //         showingEditDialog = false
                        //     }
                        // },
                        // onCancel: {
                        //     withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        //         showingEditDialog = false
                        //     }
                        // }
                    // )
                    // .offset(dialogOffset)
                    // .transition(.scale.combined(with: .opacity))
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