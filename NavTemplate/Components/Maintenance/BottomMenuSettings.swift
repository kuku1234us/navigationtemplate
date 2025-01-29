import SwiftUI
import NavTemplateShared

struct BottomMenuSettings: View {
    @StateObject private var menuModel = MenuModel.shared
    @State private var items: [MenuBarItem] = []
    
    private func loadItems() {
        // Get items from MenuModel and sort them
        items = menuModel.sortMenuItems(menuModel.menuItems)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Bottom Menu Ordering")
                .font(.title2)
                .foregroundColor(Color("PageTitle"))
                .padding(.horizontal)
                .padding(.top, 16)            
            
            List {
                ForEach(items) { item in
                    HStack(spacing: 12) {
                        Image(systemName: item.unselectedIcon)
                            .foregroundColor(Color("MySecondary"))
                            .frame(width: 24)
                        
                        Text(item.name)
                            .foregroundColor(Color("MyPrimary"))
                        
                        Spacer()
                        
                        Image(systemName: "line.3.horizontal")
                            .foregroundColor(Color("MyTertiary"))
                    }
                    .padding(.vertical, 8)
                }
                .onMove { from, to in
                    items.move(fromOffsets: from, toOffset: to)
                    
                    // Create new array with updated sort orders
                    let updatedItems = items.enumerated().map { index, item in
                        MenuBarItem(
                            id: item.id,
                            name: item.name,
                            unselectedIcon: item.unselectedIcon,
                            selectedIcon: item.selectedIcon,
                            targetView: item.targetView,
                            sortOrder: index
                        )
                    }
                    
                    // Update local state
                    items = updatedItems
                    
                    // Save to MenuModel
                    menuModel.saveMenuOrder(updatedItems)
                }
            }
            .listStyle(.plain)
        }
        .onAppear {
            loadItems()
        }
    }
} 