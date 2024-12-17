import SwiftUI
import NavTemplateShared

struct ActivityListView: View {
    @ObservedObject var activityStack: ActivityStack
    let onUndo: (ActivityItem) -> Void
    let onEdit: (ActivityItem, CGRect) -> Void
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(activityStack.allItems.reversed()) { item in
                    ActivityItemView(
                        item: item,
                        onUndo: { onUndo(item) },
                        onEdit: { frame in
                            onEdit(item, frame)
                        }
                    )
                    
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

