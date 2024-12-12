import SwiftUI

struct FrostedGlassCard: View {
    var title: String
    var description: String
    var blur: CGFloat = 8

    var body: some View {
        ZStack {
            // Card with Blur Effect
            VStack(alignment: .leading, spacing: 10) {
                Text(title)
                    .font(.title)
                    .bold()
                    .foregroundColor(.white)

                Text(description)
                    .font(.body)
                    .foregroundColor(.white)

                Spacer()
            }
            .padding()
            .frame(width: 300, height: 200)
            .backgroundBlur(radius: blur) // Frosted glass effect
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1) // Light border
            )
        }
    }
}

// Preview Example
struct FrostedGlassCard_Previews: PreviewProvider {
    static var previews: some View {
        FrostedGlassCard(
            title: "Frosted Glass Card",
            description: "This is an example of a card with a frosted glass effect."

        )
            .previewDevice("iPhone 14 Pro")
    }
}
