# Overview

The YearCarouselView system provides a performant infinite-scroll year view implementation through a combination of panel recycling, layout pre-calculation, and efficient state management. This architecture enables smooth navigation through decades of years while maintaining optimal memory usage.

## Multi-Panel Architecture

The YearCarouselView employs a vertical carousel composed of 5 YearPane panels arranged in a staggered layout:

```swift
private static let nPanels = 5
private static let halfPanels = nPanels / 2
@State private var yearDates: [Date] = []
@State private var curIndex: Int = 0
```

1. **Panel Stacking**:
   - Three visible panels (current, previous, next)
   - Two offscreen buffers for smooth transitions
   - Z-ordered by proximity to viewport center

2. **View Recycling**:
   - Each panel is reused through date reassignment
   - Maintains constant view hierarchy size
   - Eliminates allocation/deallocation overhead

## Measurement System Architecture

The YearCarouselView's layout precision is achieved through a dedicated ghost measurement system:

```swift
ZStack {
    GhostYearPage(
        reportMiniMonthRects: reportMiniMonthRects,
        ghostYearPaneRect: $ghostYearPaneRect
    )
    YearCarouselView(...)
}
```

1. **Ghost Component Hierarchy**:
   - `GhostYearPage`: Root measurement container
     - Contains `GhostYearHeader` and `GhostYearPane`
     - Reports overall year view dimensions
   - `GhostYearPane`: Measures mini-month grid layout
     - Captures positions through GeometryReader
     - Reports via `reportMiniMonthRects` closure
   - `GhostYearHeader`: Measures header dimensions

2. **Measurement Workflow**:
   - Ghost components render invisibly (opacity 0)
   - GeometryReader captures frame data
   - Closure callbacks propagate measurements:
     ```swift
     GhostYearPane(reportMiniMonthRects: { rects in
         ghostMiniMonthRects = rects
     })
     ```
   - Real components reference ghost measurements

3. **Data Flow**:
   ```mermaid
   graph TD
       A[GhostYearPage] -->|ghostYearPaneRect| B(YearCarouselView)
       A --> C[GhostYearPane]
       C -->|reportMiniMonthRects| D[CalendarHeaderView]
       C -->|ghostYearPaneRect| B
       D -->|target positions| E[Animations]
   ```

4. **Measurement Timing**:
   - Occurs during initial layout
   - Re-measures on device rotation
   - Updates when calendar type changes
   - Synchronized via DispatchQueue.main.async

5. **Critical Measurements**:
   - Mini-month title positions (short/long variants)
   - Year header height
   - Grid cell spacing
   - Overall pane dimensions

This system ensures pixel-perfect animations while decoupling measurement logic from presentation components.

## Initial Panel Arrangement

The carousel initializes with dates centered around the current year:

```swift
let baseYear = calendar.date(from: [.year])!
yearDates = (-2...2).map { 
    calendar.date(byAdding: .year, value: $0, to: baseYear)! 
}
curIndex = Self.halfPanels
```

This creates an initial date range of [current-2, current-1, current, current+1, current+2] years, with the center panel active.

## Example: User Swipes Up (Next Year)

1. Gesture begins - track vertical translation
2. Passes threshold - determine navigation direction
3. With animation:
   - Shift panels upward
   - Reassign oldest bottom panel to new future year
   - Adjust curIndex to maintain center reference
4. Completion:
   - Reset dragOffset
   - Update curDate binding
   - Pre-calculate next buffer dates

Visual layout at initialization:
```
┌─────────────────┐
│    Year -2      │ ← Offscreen buffer (index 0)
├─────────────────┤
│    Year -1      │ ← Previous year (index 1)
├─────────────────┤
│  Current Year   │ ← Center panel (index 2)
├─────────────────┤
│    Year +1      │ ← Next year (index 3)
├─────────────────┤
│    Year +2      │ ← Offscreen buffer (index 4)
└─────────────────┘
```

During user interaction, the panel stack dynamically recycles while maintaining this buffer structure:
```
Swipe Up → 
┌─────────────────┐
│    Year -1      │ ← Becomes new buffer
├─────────────────┤
│  Current Year   │ 
├─────────────────┤
│    Year +1      │ ← New center
├─────────────────┤
│    Year +2      │ 
├─────────────────┤
│    Year +3      │ ← New buffer
└─────────────────┘
```

## Panel Recycling

The recycling system maintains the infinite scroll illusion through strategic date reassignment:

1. **Scroll Detection**:
   - Vertical drag gestures tracked via `dragOffset`
   - Velocity-based completion threshold (panelHeight/5)

2. **Date Reassignment**:
   ```swift
   private func shiftPanels(direction: Int) {
       curIndex = (curIndex + direction) % Self.nPanels
       let offset = direction > 0 ? Self.halfPanels : -Self.halfPanels
       yearDates[curIndex] = calendar.date(byAdding: .year, value: offset, to: yearDates[curIndex])!
   }
   ```

3. **Visual Continuity**:
   - Animated .offset() transitions between states
   - Opacity gradients based on panel position
   - Momentum-based scrolling physics

## YearPane Implementation

The YearPane component implements intelligent rendering optimizations:

```swift
struct YearPane: View, Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        calendar.isDate(lhs.yearDate, equalTo: rhs.yearDate, toGranularity: .year)
    }
}
```

1. **Equatable Optimization**:
   - Skips re-rendering when yearDate unchanged
   - Prevents unnecessary layout passes
   - Maintains scroll position during parent updates

2. **Layout Structure**:
   ```swift
   VStack {
       ForEach(0..<4) { row in
           HStack {
               ForEach(0..<3) { col in 
                   MiniMonthCell(...)
               }
           }
       }
   }
   ```
   
   The YearPane organizes months in a 4x3 grid structure:
   - **Vertical Stack**: Contains 4 horizontal rows
   - **Horizontal Rows**: Each holds 3 MiniMonthCells
   - **Grid Flow**: Months arranged left-to-right, top-to-bottom
     - Row 0: January, February, March
     - Row 1: April, May, June
     - Row 2: July, August, September
     - Row 3: October, November, December

3. **Spacing and Alignment**:
   - Vertical spacing: 20pt between rows
   - Horizontal spacing: 15pt between cells
   - Equal width distribution using `.frame(maxWidth: .infinity)`
   - Center-aligned month titles

## MiniMonthCell Architecture

Each mini-month cell combines visual presentation with layout measurement:

1. **Dual Measurement**:
   - Captures both compact ("Jan") and expanded ("January") title frames
   - Reports view container dimensions through closure callbacks
   - Enables precise zoom animations between month/year views

2. **Visual Components**:
   - **Title Display**: Shows abbreviated month name
   - **MiniMonthView**: Compact 6-row calendar grid
     - Fixed cell size: 20x20 points
     - Reduced typographic hierarchy
     - Minimal event indicators

3. **Performance Features**:
   - Pre-calculated layout dimensions
   - Shared date formatters across instances
   - Cached month grid calculations
   - Fixed-size frame constraints

This architecture demonstrates how careful component design and system-level optimizations enable complex calendar interactions while maintaining smooth performance across all devices.



