import SwiftUI

struct MaintenanceHeaderView: View {
    @Binding var selectedTab: MaintenanceTab
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text("Maintenance")
                    .font(.largeTitle)
                    .fontWeight(.black)
                    .foregroundColor(Color("PageTitle"))
                    
                Spacer()

                // Menu bar
                HStack(spacing: 0) {
                    IconButton(
                        selectedIcon: "exclamationmark.triangle.fill",
                        unselectedIcon: "exclamationmark.triangle",
                        isSelected: .init(
                            get: { selectedTab == .logs },
                            set: { _ in selectedTab = .logs }
                        ),
                        frameSize: 30,
                        action: { selectedTab = .logs }
                    )
                    
                    IconButton(
                        selectedIcon: "folder.fill",
                        unselectedIcon: "folder",
                        isSelected: .init(
                            get: { selectedTab == .vault },
                            set: { _ in selectedTab = .vault }
                        ),
                        frameSize: 30,
                        action: { selectedTab = .vault }
                    )
                    IconButton(
                        selectedIcon: "testtube.2",
                        unselectedIcon: "testtube.2",
                        isSelected: .init(
                            get: { selectedTab == .test2 },
                            set: { _ in selectedTab = .test2 }
                        ),
                        frameSize: 30,
                        action: { selectedTab = .test2 }
                    )
                }


            }
        }
        .padding()
        .headerStyle()
    }
}

// Add enum for tab selection
enum MaintenanceTab {
    case logs
    case vault
    case test2
} 