import SwiftUI

struct InputAndIcon: View {
    @Binding var text: String
    let placeholder: String
    let icon: String
    let backgroundGradient: MeshGradient
    let backgroundOpacity: Double
    let borderOpacity: Double
    
    init(
        text: Binding<String>,
        placeholder: String = "Input...",
        icon: String = "magnifyingglass",
        backgroundOpacity: Double = 0.7,
        borderOpacity: Double = 0.2,
        backgroundGradient: MeshGradient? = nil
    ) {
        self._text = text
        self.placeholder = placeholder
        self.icon = icon
        self.backgroundOpacity = backgroundOpacity
        self.borderOpacity = borderOpacity
        self.backgroundGradient = backgroundGradient ?? MeshGradient(
            width: 3, height: 3,
            points: [
                [0.0,0.0], [0.5,0.0], [1.0,0.0],
                [0.0,0.5], [0.5,0.5], [1.0,0.5],
                [0.0,1.0], [0.5,1.0], [1.0,1.0]
            ],
            colors: [
                .white, .white, Color("Background"),
                .white, Color("Background"), Color("Background"),
                Color("Background"), Color("Background"), .black
            ]
        )
    }
    
    var body: some View {
        HStack {
            // Icon or clear button
            Button(action: {
                if !text.isEmpty {
                    text = ""
                }
            }) {
                Image(systemName: text.isEmpty ? icon : "x.circle.fill")
                    .foregroundColor(Color("MyTertiary").opacity(0.5))
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.plain)
            
            // Text field
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .foregroundColor(Color("MySecondary"))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(
            backgroundGradient
                .blendMode(.overlay)
                .opacity(backgroundOpacity)
        )
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Color("MyTertiary").opacity(borderOpacity), lineWidth: 1)
        )
    }
}
