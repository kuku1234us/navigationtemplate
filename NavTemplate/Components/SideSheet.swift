// SideSheet.swift

import SwiftUI

extension UIApplication {
    var keyWindow: UIWindow? {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }
}

struct SideSheet<Content: View>: Widget {
    let content: Content
    let direction: DragGestureHandler.DragDirection
    @ObservedObject var proxy: PropertyProxy

    var id: UUID { proxy.id }

    private var safeAreaInsets: UIEdgeInsets {
        UIApplication.shared.keyWindow?.safeAreaInsets ?? .zero
    }

    init(id: UUID, content: @escaping () -> Content, direction: DragGestureHandler.DragDirection) {
        self.content = content()
        self.direction = direction
        self.proxy = PropertyProxyFactory.shared.proxy(
            for: id,
            initialOffset: direction == .leftToRight ? 
                -SheetConstants.width : SheetConstants.width
        )
        print(">>>>> SideSheet init: \(id)")
    }

    var body: some View {
        if proxy.isActive {
            GeometryReader { geometry in
                ZStack(alignment: direction == .leftToRight ? .leading : .trailing) {
                    // Background blur
                    Rectangle()
                        .fill(Color.clear)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .backgroundBlur(radius: Double(min(1-abs(proxy.offset / SheetConstants.width), 1.0)*10), opaque: true)

                    // Overlay
                    Color.black
                        .opacity(Double(min(1-abs(proxy.offset / SheetConstants.width), 0.7)))
                        .onTapGesture {
                            NavigationState.shared.dismissSheet(
                                proxy: proxy,
                                direction: direction
                            )
                        }
                    
                    // Sheet content
                    VStack(spacing: 0) {
                        content

                    }
                    .frame(width: SheetConstants.width)
                    .padding(.top, safeAreaInsets.top)
                    .padding(.bottom, safeAreaInsets.bottom)
                    .background(Color("SideSheetBg"))
                    .offset(x: proxy.offset)
                    .edgesIgnoringSafeArea(.horizontal)
                }
                .onAppear {
                    NavigationState.shared.isBackButtonHidden = true
                }
            }
        } else {
            Color.clear
                .onDisappear {
                    // Also clean up when sheet becomes inactive
                    NavigationState.shared.isBackButtonHidden = false
                }
        }
    }
}
