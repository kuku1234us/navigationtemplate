import SwiftUI
import NavTemplateShared

struct MaintenancePage: View {
    var navigationManager: NavigationManager?
    @State private var showClearConfirmation = false
    @StateObject private var logManager = LogManager.shared
    
    var body: some View {
        ZStack {
            // Background
            Image("batmanDim")
                .resizable()
                .ignoresSafeArea()
                .overlay(.black.opacity(0.5))
            
            VStack(spacing: 0) {
                // Header
                MaintenanceHeaderView(showClearConfirmation: $showClearConfirmation)
                
                // Log List
                LogListView()
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