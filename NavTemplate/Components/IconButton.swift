import SwiftUI

struct IconButton: View {
    let selectedIcon: String
    let unselectedIcon: String
    let action: () -> Void
    let frameSize: CGFloat
    let iconSize: CGFloat
    @Binding var isSelected: Bool
    @State private var bounceValue: Int = 0
    
    init(
        selectedIcon: String,
        unselectedIcon: String? = nil,
        isSelected: Binding<Bool>,
        frameSize: CGFloat? = nil,
        iconSize: CGFloat? = nil,
        action: @escaping () -> Void
    ) {
        self.selectedIcon = selectedIcon
        self.unselectedIcon = unselectedIcon ?? selectedIcon
        
        // Default frame size is 40
        let defaultFrameSize: CGFloat = 40
        // Default icon size is 20 (half of frame size)
        let defaultIconSize: CGFloat = 20
        
        switch (frameSize, iconSize) {
        case (.some(let frame), .some(let icon)):
            // Both sizes provided - use as is
            self.frameSize = frame
            self.iconSize = icon
        case (.some(let frame), .none):
            // Only frame size provided - scale icon proportionally
            self.frameSize = frame
            self.iconSize = frame * (defaultIconSize / defaultFrameSize)
        case (.none, .some(let icon)):
            // Only icon size provided - scale frame proportionally
            self.iconSize = icon
            self.frameSize = icon * (defaultFrameSize / defaultIconSize)
        case (.none, .none):
            // No sizes provided - use defaults
            self.frameSize = defaultFrameSize
            self.iconSize = defaultIconSize
        }
        
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
                        startRadius: frameSize * 0.125,
                        endRadius: frameSize * 0.5
                    )
                    .frame(width: frameSize, height: frameSize)
                }
                
                Image(systemName: isSelected ? selectedIcon : unselectedIcon)
                    .font(.system(size: iconSize))
                    .foregroundColor(isSelected ? Color("Accent") : Color("MyTertiary"))
                    .scaleEffect(isSelected ? 1.15 : 1.0)
                    .contentTransition(.symbolEffect(.replace.offUp.byLayer))
                    .symbolEffect(.wiggle.left.byLayer, value: bounceValue)
            }
            .frame(width: frameSize, height: frameSize)
        }
        .buttonStyle(.plain)
    }
}
