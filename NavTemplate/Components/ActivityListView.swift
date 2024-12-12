import SwiftUI

struct ActivityListView: View {
    @ObservedObject var activityStack: ActivityStack
    let onUndo: (ActivityItem) -> Void
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(activityStack.allItems.reversed()) { item in
                    ActivityItemView(item: item) {
                        onUndo(item)
                    }
                    
                    if item.id != activityStack.allItems.first?.id {
                        Rectangle()
                            .fill(Color("MyTertiary"))
                            .frame(height: 1)
                            .opacity(0.2)
                    }
                }
            }
        }
        .background(Color.clear)        
        .clipShape(RoundedRectangle(cornerRadius: 30))
    }
}

#Preview {
    let stack = ActivityStack()
    // Add some sample activities
    stack.pushActivity(ActivityItem(type: .sleep, time: Date()))
    stack.pushActivity(ActivityItem(type: .wake, time: Date().addingTimeInterval(-3600)))
    stack.pushActivity(ActivityItem(type: .meal, time: Date().addingTimeInterval(-7200)))
    
    return ActivityListView(activityStack: stack) { item in
        print("Undo item: \(item.activityType.rawValue)")
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.black)
} 