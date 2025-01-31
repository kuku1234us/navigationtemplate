# Overview

This document describes the animations performed when the CalendarPage is switched between .year mode and .month mode.

## CalendarHeaderView Animations

The CalendarHeaderView orchestrates complex transitions between month/year displays through coordinated scale and position animations. When switching calendar types:

### Month → Year Transition
1. **Title Morphing**:
   - The full month title (e.g., "January") transforms into the corresponding mini-month title ("Jan") in the YearPane
   - Utilizes pre-measured positions from:
     ```swift
     GhostMonthHeader.reportMonthTitleRects()
     GhostYearPane.reportMiniMonthRects()
     ```
   - Animation path calculated via:
     ```swift
     let targetRect = ghostMiniMonthRects[monthIndex].shortTitleRect
     let scale = computeScale(source: headerTitleRect, target: targetRect)
     let offset = computeOffset(source: headerTitleRect, target: targetRect)
     ```

2. **Layout Transition**:
   - Header height collapses from expanded to compact state
   - Search field fades out with vertical offset
   - Weekday labels animate opacity to 0

### Year → Month Transition
1. **Reverse Morph**:
   - Mini-month title scales up to full header title
   - Position interpolated using GhostYearPane measurements:
     ```swift
     let sourceRect = ghostMiniMonthRects[monthIndex].longTitleRect
     let targetRect = ghostMonthLongTitleRects[monthIndex]
     ```

2. **Header Expansion**:
   - Height animates from compact to expanded
   - Weekday labels slide in with spring animation
   - Search field fades in with delay

### Technical Implementation
```swift
// Transition calculation
func computeTitleTransform(monthIndex: Int) -> (scale: CGSize, offset: CGSize) {
    let sourceRect = isYearMode ? 
        ghostMiniMonthRects[monthIndex].shortTitleRect : 
        ghostMonthLongTitleRects[monthIndex]
        
    let targetRect = isYearMode ?
        ghostMonthLongTitleRects[monthIndex] :
        ghostMiniMonthRects[monthIndex].shortTitleRect
    
    return (
        scale: CGSize(
            width: targetRect.width / sourceRect.width,
            height: targetRect.height / sourceRect.height
        ),
        offset: CGSize(
            width: targetRect.midX - sourceRect.midX,
            height: targetRect.midY - sourceRect.midY
        )
    )
}
```

### Key Animation Parameters
| Property          | Month→Year      | Year→Month      |
|-------------------|-----------------|-----------------|
| Duration          | 0.4s            | 0.5s            |
| Curve             | EaseInOut       | Spring(damping: 0.7) |
| Delay             | 0s              | 0.1s            |
| Opacity Range     | 1.0 → 0.8       | 0.8 → 1.0       |

This precise animation system creates a seamless visual connection between calendar scales while maintaining 60fps performance through pre-calculated layout data.

## MonthCarouselView Animations

The month view undergoes dimensional transformations when transitioning to year view:

1. **Miniaturization**:
   - Current month scales down to match ghostMiniMonthRect dimensions
   - Position animates to target mini-month location in year view
   - Opacity reduces to 0.2 during transition

```swift
MonthCarouselView()
  .scaleEffect(targetMonthScale)
  .offset(targetMonthOffset)
  .opacity(monthCarouselOpacity)
```

2. **Pagination Effects**:
   - Adjacent months slide with parallax effect during swipes
   - Page borders reveal through animated clip masks
   - Momentum-based deceleration using `.interactiveSpring` response

## YearCarouselView Animations

The year view employs inverse transformations when transitioning from month view:

1. **Expansion Animation**:
   - Initial scale based on ghostYearPaneRect dimensions
   - Grows to full viewport size with spring physics
   - Position synchronized with targetYearPaneOffset binding

```swift
YearCarouselView()
  .scaleEffect(targetYearPaneScale)
  .offset(targetYearPaneOffset)
```

2. **Dynamic Layout**:
   - Year panels stack with momentum-based scrolling
   - Opacity adjusts based on vertical position relative to viewport center
   - Kinetic scrolling with velocity retention

## EventListView and AddButton Animations

Secondary elements employ staged transitions to maintain visual hierarchy:

1. **Event List Exit**:
   - Slides down with 0.4s ease-out
   - Opacity reduces to 0 concurrently
   - Delayed 0.1s after calendar type change

```swift
EventListView()
  .offset(y: eventListOffset)
  .opacity(eventListOpacity)
```

2. **Add Button Animation**:
   - Spring-based entrance/exit (response: 0.4, damping: 0.7)
   - Stagger delay designed to follow to the EventListView animation

## Hierarchical Animation Coordination

The system employs phased animation groups for smooth transitions:

1. **Immediate Changes**:
   ```swift
   withAnimation(.immediate) {
       monthCarouselOpacity = 0
   }
   ```

2. **Main Sequence**:
   ```swift
   withAnimation(.spring(dampingFraction: 0.7)) {
       targetMonthScale = computeScale()
       targetMonthOffset = computeOffset()
   }
   ```

3. **Follow-through Effects**:
   ```swift
   DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
       withAnimation {
           eventListOffset = 0
       }
   }
   ```

## Performance Considerations

1. **Pre-calculation**:
   - All layout math completed before animation begins
   - Ghost components provide pre-measured geometries

2. **Frame Budgeting**:
   ```swift
   .frame(width: ghostMonthRect.width, height: ghostMonthRect.height)
   ```

3. **Texture Reuse**:
   - Shared material effects between components
   - Animated content pre-rendered in offscreen buffers

This coordinated animation system achieves complex visual transitions while maintaining 60fps performance through careful timing and resource management.
