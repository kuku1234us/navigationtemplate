import SwiftUI
import NavTemplateShared

struct ActivityItemView: View {
    let item: ActivityItem
    let onUndo: () -> Void
    let onEdit: (CGRect) -> Void
    
    @State private var itemFrame: CGRect = .zero
    
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
    
    private func formatElapsed(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval / 3600)
        let minutes = Int((timeInterval.truncatingRemainder(dividingBy: 3600)) / 60)
        return String(format: "%02d:%02d", hours, minutes)
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            // Activity Icon
            Image(systemName: item.activityType.filledIcon)
                .font(.title2)
                .foregroundColor(Color("MySecondary"))
                .frame(width: 44)
                .contentShape(Rectangle())
                .onTapGesture {
                    onEdit(itemFrame)
                }
            
            // Time and Date
            VStack(alignment: .leading, spacing: 0) {
                Text(formatTime(item.activityTime))
                    .font(.title)
                    .fontWeight(.medium)
                    .foregroundColor(Color("MyPrimary"))
                
                HStack(spacing: 8) {
                    Text(formatDate(item.activityTime))
                    Text(formatElapsed(item.timeElapsed))
                }
                .font(.footnote)
                .foregroundColor(Color("MyTertiary"))
            }
            .contentShape(Rectangle())
            .onTapGesture {
                onEdit(itemFrame)
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
        .background(GeometryReader { geo in
            Color.clear.onAppear {
                DispatchQueue.main.async {
                    itemFrame = geo.frame(in: .global)
                }
            }
            .onTapGesture {
                print("Inside ActivityItemView: Item frame: \(itemFrame)")
                // let frame = geo.frame(in: .global)
                onEdit(itemFrame)
            }
        })
    }
}

