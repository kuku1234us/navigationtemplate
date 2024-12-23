// NavTemplate/Components/UI/BottomSheet.swift

import SwiftUI
import NavTemplateShared


struct BottomSheet<Content: View>: View {
    @Binding var isPresented: Bool
    let content: () -> Content
    
    @State private var contentHeight: CGFloat = 0
    @State private var keyboardHeight: CGFloat = 0
    
    // The height of the little “drag handle” area at the top
    private let dragIndicatorHeight: CGFloat = 20
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // The actual sheet
            VStack(spacing: 0) {
                // Optional drag indicator
                Capsule()
                    .fill(Color.secondary.opacity(0.5))
                    .frame(width: 40, height: 6)
                    .padding(.top, 8)
                
                // The child content, measured
                content()
                    .background(
                        GeometryReader { geo in
                            Color.clear
                                .onAppear {
                                    self.contentHeight = geo.size.height
                                }
                                .onChange(of: geo.size.height) { newVal in
                                    self.contentHeight = newVal
                                }
                        }
                    )
            }
            .padding(.bottom, safeBottomInset()) // account for safe area if needed
            // Ensure some fallback so it's not 0
            .frame(height: max(contentHeight, 100) + dragIndicatorHeight, alignment: .top)
            .background(.regularMaterial)
            .cornerRadius(16, antialiased: true)
            .offset(y: offsetForSheet())
            .animation(.easeInOut(duration: 0.25), value: contentHeight)
            .animation(.easeInOut(duration: 0.25), value: keyboardHeight)
            .onAppear { setupKeyboardObservers() }
            
        }
        .ignoresSafeArea(edges: .bottom)
    }
    
    private func offsetForSheet() -> CGFloat {
        // SHIFT the sheet upward by keyboardHeight minus a small margin
        return keyboardHeight > 0 ? -(keyboardHeight - 10) : 0
    }
    
    private func safeBottomInset() -> CGFloat {
        let window = UIApplication.shared.keyWindow
        return window?.safeAreaInsets.bottom ?? 0
    }
    
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: .main
        ) { notification in
            if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                withAnimation {
                    self.keyboardHeight = keyboardFrame.height
                }
            }
        }
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main
        ) { _ in
            withAnimation {
                self.keyboardHeight = 0
            }
        }
    }
}
