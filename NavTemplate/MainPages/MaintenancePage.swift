import SwiftUI
import NavTemplateShared

struct MaintenancePage: View {
    var navigationManager: NavigationManager?
    @StateObject private var logManager = LogManager.shared
    @State private var selectedTab: MaintenanceTab = .logs
    
    var body: some View {
        ZStack {
            // Background
            Image("batmanDim")
                .resizable()
                .ignoresSafeArea()
                .overlay(.black.opacity(0.5))
            
            VStack(spacing: 0) {
                // Header with menu bar
                MaintenanceHeaderView(selectedTab: $selectedTab)
                
                // Content based on selected tab
                if selectedTab == .logs {
                    LogListView()
                } else if selectedTab == .vault {
                    iCloudPage()
                } else if selectedTab == .test2 {
                    Test2()
                } else if selectedTab == .menuSettings {
                    BottomMenuSettings()
                }
                Spacer()
            }
        }
    }
} 