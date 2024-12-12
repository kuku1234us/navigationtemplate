import SwiftUI

struct ActivityItemView: View {
    let item: ActivityItem
    let onUndo: () -> Void
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd"
        return formatter.string(from: date).uppercased()
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            // Activity Icon
            Image(systemName: item.activityType.filledIcon)
                .font(.title2)
                .foregroundColor(Color("MySecondary"))
                .frame(width: 44)
            
            // Time and Date
            VStack(alignment: .leading, spacing: 0) {
                Text(formatTime(item.activityTime))
                    .font(.title)
                    .fontWeight(.medium)
                    .foregroundColor(Color("MyPrimary"))
                
                Text(formatDate(item.activityTime))
                    .font(.footnote)
                    .foregroundColor(Color("MyTertiary"))
            }
            
            Spacer()
            
            // Undo Button
            Button(action: onUndo) {
                Image(systemName: "arrow.clockwise.circle")
                    .font(.title2)
                    .foregroundColor(Color("MySecondary"))
            }
        }
        .padding()
        .background(Color("SideSheetBg").opacity(0.2))
    }
}

#Preview {
    VStack(spacing: 20) {
        ActivityItemView(
            item: ActivityItem(type: .sleep, time: Date()),
            onUndo: { print("Undo tapped") }
        )
        ActivityItemView(
            item: ActivityItem(type: .wake, time: Date().addingTimeInterval(-3600)),
            onUndo: { print("Undo tapped") }
        )
        ActivityItemView(
            item: ActivityItem(type: .meal, time: Date().addingTimeInterval(-7200)),
            onUndo: { print("Undo tapped") }
        )
    }
    .padding()
    .background(Color.black)
} 