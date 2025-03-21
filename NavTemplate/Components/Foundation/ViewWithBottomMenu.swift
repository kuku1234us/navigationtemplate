import SwiftUI
import NavTemplateShared

struct ViewWithBottomMenu: View {
    let items: [MenuBarItem]
    @State private var selectedIndex: Int = 0
    @State private var bounceValues: [Int] = Array(repeating: 0, count: 10)  // Support up to 10 menu items
    @StateObject private var menuModel = MenuModel.shared
    
    private var sortedItems: [MenuBarItem] {
        menuModel.sortMenuItems(items)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                sortedItems[selectedIndex].targetView
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    // .animation(.easeInOut(duration: 0.3), value: selectedIndex)
                
                // Bottom menu
                VStack {
                    Spacer()
                    HStack {
                        ForEach(sortedItems.indices, id: \.self) { index in
                            Spacer()
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6, blendDuration: 0.6)) {
                                    selectedIndex = index
                                    bounceValues[index] += 1  // Only increment for selected icon
                                }
                            }) {
                                    ZStack {
                                        if selectedIndex == index {
                                            RadialGradient(
                                                gradient: Gradient(colors: [Color("Accent").opacity(0.20), .clear]),
                                                center: .center,
                                                startRadius: 5,
                                                endRadius: 20
                                            )
                                            .frame(width: 50, height: 50)
                                        }

                                        Image(systemName: selectedIndex == index ? sortedItems[index].selectedIcon : sortedItems[index].unselectedIcon)
                                            .font(.system(size: 20))
                                            .foregroundColor(selectedIndex == index ? Color("Accent") : Color("MyTertiary"))
                                            .scaleEffect(selectedIndex == index ? 1.15 : 1.0)
                                            .contentTransition(.symbolEffect(.replace.offUp.byLayer))
                                            .symbolEffect(.wiggle.left.byLayer, value: bounceValues[index])
                                    }
                                    .frame(width: 50, height: 50)
                            }
                            Spacer()
                        }
                    }
                    .padding(.horizontal, 15)
                    .padding(.bottom, 20)
                    .frame(width: geometry.size.width, height: NavigationState.bottomMenuHeight)
                    .backgroundBlur(radius: 10, opaque: true)
                    .background(Color("SideSheetBg").opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .innerShadow(shape: RoundedRectangle(cornerRadius: 20), color: Color.bottomSheetBorderMiddle , lineWidth: 1, offsetX: 0, offsetY: 1, blur: 0, blendMode: .overlay, opacity: 1)
                }
            }
        }
    }
}
