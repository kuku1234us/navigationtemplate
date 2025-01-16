import SwiftUI

struct ReminderBadge: View {
    let minutes: Int
    let onRemove: () -> Void
    
    private var displayText: String {
        if minutes >= 1440 { // 24 hours
            let days = minutes / 1440
            return "\(days)d"
        } else if minutes >= 60 {
            let hours = minutes / 60
            return "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "bell.fill")
                .font(.system(size: 10))
            
            Text(displayText)
                .font(.system(size: 12))
            
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color("MyTertiary"))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color("SideSheetBg").opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color("MyTertiary").opacity(0.2), lineWidth: 1)
        )
    }
} 