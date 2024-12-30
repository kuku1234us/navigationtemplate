import SwiftUI
import NavTemplateShared

struct LogListEntryView: View {
    let logListEntry: Logger.LogListEntry
    @State private var isExpanded = true
    @State private var showCopiedFeedback = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            // Header with target name and buttons
            HStack {
                Text(logListEntry.target)
                    .font(.headline)
                    .foregroundColor(Color("MyPrimary"))
                
                Spacer()
                
                // Copy button
                Button(action: {
                    copyToClipboard()
                    showCopiedFeedback = true
                    
                    // Hide feedback after delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        showCopiedFeedback = false
                    }
                }) {
                    Image(systemName: showCopiedFeedback ? "checkmark" : "doc.on.doc")
                        .foregroundColor(showCopiedFeedback ? Color("Accent") : Color("MyTertiary"))
                        .font(.system(size: 14, weight: .semibold))
                }
                .padding(.trailing, 8)
                
                // Expand/collapse button
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                }) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .foregroundColor(Color("MyTertiary"))
                        .font(.system(size: 14, weight: .semibold))
                        .frame(width: 20)
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 5)
            
            // Log entries (shown only when expanded)
            if isExpanded {
                ForEach(logListEntry.logs, id: \.self) { log in
                    LogEntryView(logEntry: log)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical)
        .background(Color("SideSheetBg").opacity(0.2))
        .withTransparentRectangleStyle()
    }
    
    private func copyToClipboard() {
        let logText = logListEntry.logs.joined(separator: "\n")
        UIPasteboard.general.string = logText
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
} 