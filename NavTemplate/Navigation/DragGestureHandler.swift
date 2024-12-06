// DragGestureHandler.swift
//
// Requirements:
// 1. Handle drag gestures for SideSheet with specific direction (left-to-right or right-to-left)
// 2. Determine if a drag should be handled based on:
//    - Initial direction of drag
//    - Horizontal vs vertical movement ratio
// 3. Track and update drag state:
//    - Drag offset for sheet position
//    - Translation for debugging
//    - Active state management
//
// Functionality:
// - Early direction detection with 5px minimum distance
// - One-time direction check per drag sequence
// - Continuous drag tracking once committed
// - Threshold-based completion/cancellation
// - Animation timing for smooth transitions
// - Debug information for development

import SwiftUI

struct DragGestureHandler: Gesture {
    @Binding var offset: CGFloat
    @Binding var isActive: Bool
    @Binding var debugText: String
    @Binding var translation: CGPoint
    @Binding var isDragging: Bool
    @Binding var isExpanded: Bool

    private let direction: DragDirection
    private let maxOffset: CGFloat
    private let minimumDistance: CGFloat = 5

    // State tracking
    @State private var directionChecked: Bool = false
    @State private var prevDragChange: CGFloat = 0
    @State private var lastDragDirection: DragDirection?

    enum DragDirection {
        case rightToLeft
        case leftToRight
        
        static func from(currentChange: CGFloat, previousChange: CGFloat) -> DragDirection {
            (currentChange - previousChange) > 0 ? .leftToRight : .rightToLeft
        }
    }

    init(offset: Binding<CGFloat>,
         isActive: Binding<Bool>,
         debugText: Binding<String>,
         translation: Binding<CGPoint>,
         isDragging: Binding<Bool>,
         isExpanded: Binding<Bool>,
         direction: DragDirection) {
        self._offset = offset
        self._isActive = isActive
        self._debugText = debugText
        self._translation = translation
        self._isDragging = isDragging
        self._isExpanded = isExpanded
        self.direction = direction
        self.maxOffset = SheetConstants.width
    }

    var body: some Gesture {
        DragGesture(minimumDistance: minimumDistance)
            .onChanged { value in
                // Begin dragging
                isDragging = true
                
                debugText="isExpanded: \(isExpanded)"

                // Calculate drag change based on current expansion state
                let dragChange = isExpanded ? 
                    maxOffset + value.translation.width : // Start from maxOffset if expanded
                    value.translation.width               // Start from 0 if retracted
                
                // Update translation for debugging
                translation = CGPoint(
                    x: dragChange,
                    y: value.translation.height
                )
                
                // Update current drag direction
                if dragChange != prevDragChange {
                    lastDragDirection = DragDirection.from(
                        currentChange: dragChange,
                        previousChange: prevDragChange
                    )
                    prevDragChange = dragChange
                }

                if !directionChecked {
                    // One-time direction check
                    let isHorizontal = abs(value.translation.width) > abs(value.translation.height)
                    let isCorrectDirection = direction == .leftToRight ? dragChange > 0 : dragChange < 0

                    directionChecked = true
                    if (!isExpanded) {
                        if  isHorizontal && isCorrectDirection {
                            debugText = "Activating widget"
                            isActive = true
                            offset = dragChange
                        } else {
                            // Ignore drag if not correct direction
                            isActive = false
                        }
                    } else {
                        offset = min(max(0, dragChange), maxOffset)
                    }
                } else if isActive {
                    // Update offset without animation during drag
                    offset = min(max(0, dragChange), maxOffset)
                }
            }
            .onEnded { value in
                isDragging = false
                
                if isActive {
                    // First determine the target state
                    let shouldExpand = lastDragDirection == .leftToRight
                    
                    if shouldExpand {
                        NavigationState.shared.expandSheet(offset: $offset)
                        isExpanded = true
                    } else {
                        NavigationState.shared.dismissSheet(isActive: $isActive, offset: $offset)
                        isExpanded = false
                    }
                }

                // Reset direction check when gesture ends
                directionChecked = false
                lastDragDirection = nil
                prevDragChange = 0
            }
    }
}
