import SwiftUI

struct TaskHeaderView: View {
    @State private var sortSelected: Bool = false
    @State private var filterSelected: Bool = false
    @Binding var showSortMenu: Bool
    @Binding var searchText: String
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Tasks")
                    .font(.largeTitle)
                    .fontWeight(.black)
                    .foregroundColor(Color("PageTitle"))
                
                Spacer()
                            // Search field
            TaskSearchField(text: $searchText)
                .padding(.horizontal, 12)


                Spacer()

                
                // Sort and Filter buttons
                HStack(spacing: 0) {
                    IconButton(
                        selectedIcon: "align.horizontal.left.fill",
                        unselectedIcon: "align.horizontal.left",
                        isSelected: $showSortMenu,
                        action: {
                            UIImpactFeedbackGenerator.impact(.light)
                            showSortMenu.toggle()
                        }
                    )
                }
            }
            
        }
        .padding()
        .headerStyle()
    }
} 