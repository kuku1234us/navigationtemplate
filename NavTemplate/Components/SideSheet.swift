// SideSheet.swift

import SwiftUI

struct SideSheet<Content: View>: Widget {
    let id = UUID()
    let content: Content
    @Binding var isActive: Bool
    @Binding var offset: CGFloat
    @Binding var isDragging: Bool
    @Binding var isExpanded: Bool
    @Binding var directionChecked: Bool
    
    // Standard colors and dimensions
    private let backgroundColor = Color(uiColor: .systemGray6)
    private let overlayColor = Color.black
    
    init(content: @escaping () -> Content,
         isActive: Binding<Bool>,
         offset: Binding<CGFloat>,
         isDragging: Binding<Bool>,
         isExpanded: Binding<Bool>,
         directionChecked: Binding<Bool>) {
        self.content = content()
        self._isActive = isActive
        self._offset = offset
        self._isDragging = isDragging
        self._isExpanded = isExpanded
        self._directionChecked = directionChecked
    }
    
    var body: some View {
        if isActive || offset > 0 {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background blur
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .opacity(Double(min(offset / SheetConstants.width, 0.7)))
                        .ignoresSafeArea()
                    // Overlay
                    overlayColor
                        .opacity(Double(min(offset / SheetConstants.width, 0.6)))
                        .ignoresSafeArea()
                        .onTapGesture {
                            NavigationState.shared.dismissSheet(
                                isActive: $isActive,
                                offset: $offset,
                                isExpanded: $isExpanded,
                                directionChecked: $directionChecked,
                                isDragging: $isDragging
                            )
                        }
                    
                    // Sheet content
                    VStack {
                        content
                    }
                    .frame(width: SheetConstants.width)
                    .background(backgroundColor)
                    .offset(x: -SheetConstants.width + offset)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
                // Only use animation(.easeInOut) when not dragging and offset is not changing
                .animation(isDragging ? nil : .easeInOut, value: offset)
            }
            .ignoresSafeArea()
            .onAppear {
                NavigationState.shared.isBackButtonHidden = true
            }
        } else {
            Color.clear
                .onAppear {
                    NavigationState.shared.isBackButtonHidden = false
                }
        }
    }
}

