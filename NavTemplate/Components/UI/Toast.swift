import SwiftUI

struct Toast: View {
    enum ToastType {
        case success
        case error
        
        var color: Color {
            switch self {
            case .success: return .green
            case .error: return .red
            }
        }
        
        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .error: return "exclamationmark.circle.fill"
            }
        }
    }
    
    let type: ToastType
    let title: String
    let message: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Image(systemName: type.icon)
                Text(title)
                    .font(.headline)
            }
            if !message.isEmpty {
                Text(message)
                    .font(.subheadline)
            }
        }
        .foregroundColor(.white)
        .padding()
        .background(type.color.opacity(0.9))
        .cornerRadius(10)
        .shadow(radius: 5)
    }
}

struct ToastModifier: ViewModifier {
    @Binding var isPresenting: Bool
    let duration: TimeInterval
    let toast: () -> Toast
    
    func body(content: Content) -> some View {
        content
            .overlay(
                ZStack {
                    if isPresenting {
                        toast()
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                                    withAnimation {
                                        isPresenting = false
                                    }
                                }
                            }
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
                .animation(.spring(), value: isPresenting)
                , alignment: .top
            )
    }
}

extension View {
    func toast(isPresenting: Binding<Bool>, duration: TimeInterval = 3, toast: @escaping () -> Toast) -> some View {
        modifier(ToastModifier(isPresenting: isPresenting, duration: duration, toast: toast))
    }
} 