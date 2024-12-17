import SwiftUI

struct SmallButton: View {
    let icon: String
    let iconColor: Color
    
    var body: some View {
        ZStack {
            // Inner Circle Shadow
            Circle()
                .fill(Color("MySecondary").opacity(0.2))
                .frame(width: 35, height: 35)                
                .shadow(color: .white.opacity(0.1), radius: 5, x: -2, y: -2)

            // Inner Circle
            Circle()
                .fill(Color("MySecondary").opacity(0.2))
                .overlay {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(stops: [
                                    .init(color: .white.opacity(0.1), location: 0),
                                    .init(color: .white.opacity(0.1), location: 0.5),
                                    .init(color: .black.opacity(0.5), location: 1)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .blendMode(.overlay)
                        .frame(width: 35, height: 35)
                }
                .frame(width: 35, height: 35)
                .overlay {
                    Circle()
                        .fill(.clear)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(stops: [
                                    .init(color: .white.opacity(0.7), location: 0),
                                    .init(color: .black.opacity(0.05), location: 0.4),
                                    .init(color: .black.opacity(0.05), location: 0.6),
                                    .init(color: .white.opacity(0.2), location: 1)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 3
                        )
                        .blendMode(.overlay)
                        .clipShape(Circle())                            
                }                
                .frame(width: 35, height: 35)
                .border(.clear, width: 0)

            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(iconColor)
        }
        .frame(minWidth: 45, minHeight: 45)
    }
} 