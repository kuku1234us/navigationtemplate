import SwiftUI

struct TaskHeaderView: View {
    @State private var sortSelected: Bool = false
    @State private var filterSelected: Bool = false
    @Binding var showSortMenu: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Tasks")
                    .font(.largeTitle)
                    .fontWeight(.black)
                    .foregroundColor(Color("PageTitle"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                
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
                    
                    IconButton(
                        selectedIcon: "slider.horizontal.below.square.filled.and.square",
                        unselectedIcon: "slider.horizontal.below.square.filled.and.square",
                        isSelected: $filterSelected,
                        action: {
                            filterSelected.toggle()
                        }
                    )
                }
            }
        }

        .withSafeAreaTop()
        .padding()
        .backgroundBlur(radius: 10, opaque: true)
        .background(
            MeshGradient(
                width: 3, height: 3,
                points: [
                    [0.0,0.0], [0.5,0.0], [1.0,0.0],
                    [0.0,0.5], [0.5,0.5], [1.0,0.5],
                    [0.0,1.0], [0.5,1.0], [1.0,1.0]
                ],
                colors: [
                    Color("Background"),Color("Background"),.black,
                    .blue,Color("Background"),Color("Background"),
                    .blue,.blue,Color("Background"),                    
                ]
            )
            .opacity(0.1)
        )
    }
} 