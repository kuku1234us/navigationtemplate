import SwiftUI
import NavTemplateShared

struct LogListView: View {
    @StateObject private var logManager = LogManager.shared
    
    var body: some View {
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
}