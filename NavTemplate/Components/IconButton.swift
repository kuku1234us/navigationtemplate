import SwiftUI

struct IconButton: View {
    let selectedIcon: String
    let unselectedIcon: String
    let action: () -> Void
    @Binding var isSelected: Bool
    @State private var bounceValue: Int = 0
    
    init(
        selectedIcon: String,
        unselectedIcon: String? = nil,
        isSelected: Binding<Bool>,
        action: @escaping () -> Void
    ) {
        self.selectedIcon = selectedIcon
        self.unselectedIcon = unselectedIcon ?? selectedIcon
        self._isSelected = isSelected
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            action()
            if isSelected {
                bounceValue += 1
            }
        }) {
            ZStack {
                if isSelected {
                    RadialGradient(
                        gradient: Gradient(colors: [Color("Accent").opacity(0.20), .clear]),
                        center: .center,
                        startRadius: 5,
                        endRadius: 20
                    )
                    .frame(width: 40, height: 40)
                }
                
                Image(systemName: isSelected ? selectedIcon : unselectedIcon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? Color("Accent") : Color("MyTertiary"))
                    .scaleEffect(isSelected ? 1.15 : 1.0)
                    .contentTransition(.symbolEffect(.replace.offUp.byLayer))
                    .symbolEffect(.wiggle.left.byLayer, value: bounceValue)
            }
            .frame(width: 40, height: 40)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HStack {
        IconButton(
            selectedIcon: "star.fill",
            unselectedIcon: "star",
            isSelected: .constant(true),
            action: {}
        )
        
        IconButton(
            selectedIcon: "heart.fill",
            unselectedIcon: "heart",
            isSelected: .constant(false),
            action: {}
        )
    }
} 