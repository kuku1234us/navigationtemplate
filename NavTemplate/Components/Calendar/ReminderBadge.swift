import SwiftUI

struct ReminderBadge: View {
    let minutes: Int
    let onRemove: () -> Void
    
    private var displayText: String {
        if minutes == 0 {
            return "@"
        }
        
        var components: [String] = []
        var remainingMinutes = minutes
        
        // Calculate weeks
        if remainingMinutes >= 10080 { // 7 * 24 * 60
            let weeks = remainingMinutes / 10080
            components.append("\(weeks)w")
            remainingMinutes %= 10080
        }
        
        // Calculate days
        if remainingMinutes >= 1440 { // 24 * 60
            let days = remainingMinutes / 1440
            components.append("\(days)d")
            remainingMinutes %= 1440
        }
        
        // Calculate hours
        if remainingMinutes >= 60 {
            let hours = remainingMinutes / 60
            components.append("\(hours)h")
            remainingMinutes %= 60
        }
        
        // Add remaining minutes
        if remainingMinutes > 0 {
            components.append("\(remainingMinutes)m")
        }
        
        // Join all components
        return components.joined(separator: " ")
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