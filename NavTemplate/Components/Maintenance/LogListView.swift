import SwiftUI
import NavTemplateShared

struct LogListView: View {
    @StateObject private var logManager = LogManager.shared
    @State private var showClearConfirmation = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Trash button row
            Button(action: {
                showClearConfirmation = true
            }) {
                HStack {
                    Image(systemName: "trash")
                        .foregroundColor(Color("MyTertiary"))
                    Text("Clear All Logs")
                        .foregroundColor(Color("MySecondary"))
                    Spacer()
                }
                .padding()
                .background(Color("SideSheetBg").opacity(0.5))
            }
            
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 5) {
                    ForEach(logManager.logList, id: \.target) { logListEntry in
                        LogListEntryView(logListEntry: logListEntry)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 16)
            }
        }
        .alert("Clear Logs", isPresented: $showClearConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                logManager.clearLogs()
            }
        } message: {
            Text("Are you sure you want to clear all logs?")
        }
    }
}