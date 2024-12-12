// CircleButton.swift

import SwiftUI

struct CircleButton: View {
    var icon: String
    var iconColor: Color
    var buttonColor: Color
    var action: (() -> Void)? = nil
    
    var body: some View {
        ZStack {
            // Outer Ring Rim
            Circle()
                .fill(buttonColor)
                .overlay{
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(stops: [
                                    .init(color: .black.opacity(0), location: 0),
                                    .init(color: .black.opacity(0), location: 0.5),
                                    .init(color: .black.opacity(0.5), location: 1)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .blendMode(.overlay)
                }
                .overlay {
                    Circle()
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(stops: [
                                    .init(color: .white.opacity(1), location: 0),
                                    .init(color: .white.opacity(0.1), location: 1)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 3
                        )
                        .blendMode(.overlay)
                }
                .frame(width: 80, height: 80)
            
            // Sunken Center
            Circle()
                .fill(buttonColor)
                .overlay {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(stops: [
                                    .init(color: .black.opacity(0.2), location: 0),
                                    .init(color: .black.opacity(0.8), location: 1)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 60, height: 60)
                }
                .overlay {
                    Circle()
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(stops: [
                                    .init(color: .white.opacity(0.3), location: 0),
                                    .init(color: .white.opacity(0), location: 1)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1
                        )
                        .blendMode(.overlay)
                }
                .shadow(color: .white.opacity(0.1), radius: 2, x: -2, y: -2)
                .frame(width: 60, height: 60)

            // Inner Cirle Shadow
            Circle()
                .fill(buttonColor)
                .frame(width: 40, height: 40)                
                .shadow(color: .white.opacity(0.1), radius: 5, x: -2, y: -2)

            // Inner Circle
            Circle()
                .fill(buttonColor)
                .overlay {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(stops: [
                                    .init(color: .white.opacity(0.5), location: 0),
                                    .init(color: .white.opacity(0.5), location: 0.5),
                                    .init(color: .black.opacity(0.5), location: 1)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .blendMode(.overlay)
                        .frame(width: 40, height: 40)
                }
                .frame(width: 40, height: 40)
                .overlay {
                    Circle()
                        .fill(.clear)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(stops: [
                                    .init(color: .white.opacity(0.9), location: 0),
                                    .init(color: .black.opacity(0.05), location: 0.4),
                                    .init(color: .black.opacity(0.05), location: 0.6),
                                    .init(color: .white.opacity(0.6), location: 1)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 3
                        )
                        .blendMode(.overlay)
                        
                }                
                .frame(width: 40, height: 40)

            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(iconColor)
        }
        .onTapGesture {
            action?()
        }
    }
}

