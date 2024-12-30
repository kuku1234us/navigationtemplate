import SwiftUI

struct LogEntryView: View {
    let logEntry: String
    @State private var showCopiedFeedback = false
    
    var body: some View {
        HStack(spacing: 0) {
            Text(cleanLogEntry)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(showCopiedFeedback ? Color("Accent") : Color("MySecondary"))
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color("SideSheetBg").opacity(0.2))
                .overlay(
                    Rectangle()
                        .fill(logColor)
                        .frame(width: 3),
                    alignment: .leading
                )
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 8)
        .contentShape(Rectangle())  // Make entire area tappable
        .onTapGesture {
            copyToClipboard()
            showCopiedFeedback = true
            
            // Hide feedback after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                showCopiedFeedback = false
            }
        }
    }
    
    private func copyToClipboard() {
        UIPasteboard.general.string = logEntry
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    
    private var cleanLogEntry: String {
        // First remove the timestamp and target name
        if let firstSpaceIndex = logEntry.firstIndex(of: " "),
           let colonIndex = logEntry[firstSpaceIndex...].firstIndex(of: ":") {
            let messageStart = logEntry.index(after: colonIndex)
            let message = String(logEntry[messageStart...])
                .trimmingCharacters(in: .whitespaces)
                // Then remove the log level indicators
                .replacingOccurrences(of: "【Info】", with: "")
                .replacingOccurrences(of: "【Debug】", with: "")
                .replacingOccurrences(of: "【Error】", with: "")
                .trimmingCharacters(in: .whitespaces)
            return message
        }
        return logEntry
    }
    
    private var logColor: Color {
        if logEntry.contains("【Error】") {
            return Color("UrgentPriorityColor")
        } else if logEntry.contains("【Debug】") {
            return Color("NormalPriorityColor")
        } else {
            return Color("LowPriorityColor")
        }
    }
}