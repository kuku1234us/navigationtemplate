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
        ZStack() {
            VStack(spacing: 0) {
                Spacer()

                VStack(spacing:0) {
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
                                        .onChange(of: geo.size.height) { oldValue, newValue in
                                            self.contentHeight = newValue
                                        }
                                }
                            )
                    }
                    .frame(height: max(contentHeight, 100) + dragIndicatorHeight, alignment: .top)
                    .onAppear { setupKeyboardObservers() }

                    // Only show rectangle when keyboard is hidden
                    if keyboardHeight == 0 {
                        Rectangle()
                            .fill(.clear)
                            .frame(height: NavigationState.bottomMenuHeight)
                            .background(.clear)
                    }
                }
                .background(Color("Background").opacity(0.7))
                .withTransparentRoundedTopStyle()
                .offset(y: offsetForSheet())
                .animation(.easeInOut(duration: 0.25), value: contentHeight)
                .animation(.easeInOut(duration: 0.25), value: keyboardHeight)
            }
            .frame(maxWidth: .infinity,maxHeight: .infinity)
            .ignoresSafeArea()
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
