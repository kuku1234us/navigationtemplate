# Overview

The CalendarPage is the main view for the Calendar Management. The default view is the Month view.

# CalendarView

The CalendarView is the main view of the CalendarPage. It displays the MonthCarouselView and the CalendarHeaderView.

## Implementation

- **MonthCarouselView:** Displays the MonthCarouselView, which allows users to swipe between months.
- **CalendarHeaderView:** Displays the CalendarHeaderView, which shows the current month and allows switching between different calendar views (Month, Year, Day).
- **curDate:** A binding to the current date being viewed. This date is central to the calendar's functionality, as it synchronizes the display between the `CalendarHeaderView` and the `MonthCarouselView`. When the user navigates through the carousel or selects a date, `curDate` updates to reflect the new selection, ensuring both the header and carousel are in sync.
- **calendarType:** A binding to the current calendar type being viewed (e.g., Month, Year, Day). This determines the layout and functionality of the calendar display. For instance, when the user switches from Month to Year view, `calendarType` updates, prompting the `CalendarView` to adjust its layout and content accordingly.

# CalendarHeaderView

The CalendarHeaderView is the top view of the CalendarPage. It displays the current month being viewed and allows the User to switch between Month (default), Year, and Day views.

## Implementation

# MonthCarouselView

The MonthCarouselView is an infinite carousel of MonthViews that allows the User to navigate between months by swiping left and right.

## Implementation

- **Panel Arrangement:**
  - The carousel consists of a fixed number of panels (5 in this case) that are arranged in a ZStack.
  - The panels are positioned such that the middle panel is the current month, with two panels on either side representing previous and next months.

### Visual Representation

- **Recycling Mechanism:**
  - As the user swipes left or right, the panels are recycled to create the illusion of an infinite carousel.
  - When a panel moves off-screen, it is repositioned to the opposite end of the carousel with a new month date.
  - This is achieved by updating the `monthDates` array and reusing the existing MonthView components.
  - Each time the carousel rotates, an off-screen panel is rerendered invisibly with the new month data, ensuring smooth transitions.

### Interaction Example

- **Initial State:**
  ```
  [Jan] [Feb] [Mar] [Apr] [May]
  ```

- **Swipe Left (to move forward):**
  ```
  [Feb] [Mar] [Apr] [May] [Jun]
  ```

- **Swipe Right (to move backward):**
  ```
  [Dec] [Jan] [Feb] [Mar] [Apr]
  ```

- **Infinite Scrolling Illusion:**
  - The carousel uses modular arithmetic to calculate the new positions and dates for the panels.
  - This ensures that the panels wrap around seamlessly, providing a continuous scrolling experience.
  
### Structure

- **State Variables:**
  - `currentDate`: A binding to the main date tracked externally.
  - `monthDates`: An array storing a representative date for each month displayed in the carousel.
  - `curIndex`: Tracks which panel is currently centered.
  - `dragOffset`: Tracks the horizontal drag offset during user interaction.
  - `monthViewHeight`: Stores the dynamic height of the month view.
  - `isDragging`: A boolean indicating if a drag gesture is active.

### Initialization

- Initializes `monthDates` with five representative dates centered around the current date.
- Sets `curIndex` to the middle panel.

### Gesture Handling

- **DragGesture:**
  - Updates `dragOffset` during the drag.
  - On release, determines if the swipe was sufficient to change months.
  - Animates the transition and updates `curIndex` and `monthDates` accordingly.

### View Composition

- Uses a `ZStack` to overlay `MonthView` panels.
- Each `MonthView` is bound to an element in `monthDates`.
- Displays a right border during dragging for visual feedback.

# MonthView

The MonthView displays one month of the calendar. Each week is a row from Sunday to Saturday. The User can tap on a day to view the events for that day.

## Implementation

### Structure

- **Binding:**
  - `monthDate`: A binding to a representative date within the month being displayed. This date is used to determine the month and highlight the selected day.

### Date Calculation

- Generates a 6x7 matrix of dates for the month, accounting for leading and trailing days from adjacent months.

### User Interaction

- Allows tapping on a date to update `monthDate`.
- Highlights the selected date with a circle.
- Highlights today's date with the distinctive `Accent` background and Black text.

### View Composition

- Uses a `VStack` and `HStack` to layout weeks and days.
- Each day is represented by a `Text` view with conditional styling based on its state (today, selected, or regular).

This documentation provides a comprehensive overview of how the `MonthCarouselView` and `MonthView` are structured and function within the calendar system.
