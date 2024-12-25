// DragGestureHandler.swift

import SwiftUI

struct DragGestureHandler: Gesture {
    @ObservedObject var proxy: PropertyProxy
    let direction: DragDirection
    private let maxOffset: CGFloat
    private let minOffset: CGFloat
    private let minimumDistance: CGFloat = 5
    private let id: UUID

    enum DragDirection {
        case rightToLeft
        case leftToRight

        static func determineDirection(curChange: CGFloat, prevChange: CGFloat) -> DragDirection {
            (curChange - prevChange) > 0 ? .leftToRight : .rightToLeft
        }
    }

    init(proxy: PropertyProxy, direction: DragDirection) {
        self.id = UUID()
        self.proxy = proxy
        self.direction = direction
        self.maxOffset = direction == .leftToRight ? 0 : SheetConstants.width
        self.minOffset = direction == .leftToRight ? -SheetConstants.width : 0
    }

    var body: some Gesture {
        DragGesture(minimumDistance: minimumDistance)
            .onChanged { value in
                // Check if there's an active widget
                if NavigationState.shared.getActiveWidgetId() != nil {
                    // Give up if Active Widget is not this widget
                    if NavigationState.shared.getActiveWidgetId() != proxy.id {
                        return
                    }
                }

                let curDragChange = value.translation.width

                if curDragChange != proxy.prevDragChange {
                    proxy.lastDragDirection = DragDirection.determineDirection(
                        curChange: curDragChange,
                        prevChange: proxy.prevDragChange
                    )
                    proxy.prevDragChange = curDragChange
                }

                if !proxy.directionChecked {
                    proxy.directionChecked = true

                    let isHorizontal = abs(curDragChange) > abs(value.translation.height)
                    let isCorrectDirection: Bool = {
                        switch direction {
                        case .leftToRight:
                            return curDragChange > 0
                        case .rightToLeft:
                            return curDragChange < 0
                        }
                    }()

                    if isHorizontal && (isCorrectDirection || proxy.isExpanded) {
                        proxy.isActive = true
                        NavigationState.shared.setActiveWidgetId(proxy.id)

                        let tempOffset = min(max(minOffset, curDragChange), maxOffset)
                        if direction == .leftToRight {
                            proxy.offset = tempOffset + (proxy.isExpanded ? 0 : -SheetConstants.width)
                        } else {
                            proxy.offset = tempOffset + (proxy.isExpanded ? 0 : SheetConstants.width)
                        }
                    } 
                } else if proxy.isActive {
                    let baseOffset: CGFloat
                    if proxy.isExpanded {
                        baseOffset = 0
                    } else {
                        baseOffset = direction == .leftToRight ? -SheetConstants.width : SheetConstants.width
                    }
                    proxy.offset = baseOffset + curDragChange
                    proxy.offset = min(max(minOffset, proxy.offset), maxOffset)
                }
            }
            .onEnded { value in
                if proxy.isActive {
                    let shouldExpand = (direction == .leftToRight && proxy.lastDragDirection == .leftToRight)
                        || (direction == .rightToLeft && proxy.lastDragDirection == .rightToLeft)

                    withAnimation(.easeOut(duration: 0.2)) {
                        if shouldExpand {
                            NavigationState.shared.expandSheet(proxy: proxy)
                            proxy.isExpanded = true
                        } else {
                            NavigationState.shared.dismissSheet(
                                proxy: proxy,
                                direction: direction
                            )
                            proxy.isExpanded = false
                        }
                    }
                }

                proxy.directionChecked = false
                // proxy.lastDragDirection = nil
                proxy.prevDragChange = 0
            }
    }
}
