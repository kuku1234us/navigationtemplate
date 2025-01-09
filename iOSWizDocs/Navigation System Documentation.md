---
tags: swift
---

## Overview

The navigation system is designed to provide a scalable and robust architecture for managing pages and navigation in a SwiftUI iOS application (iOS 17 or later). It allows for the creation of various types of pages, such as **ProjectPage**, **DailyPage**, **BookPage**, and **EventPage**, each potentially accepting its own set of parameters. The system manages a navigation path that enables users to navigate back and forth between previously visited pages, similar to a web browser.

**Key Features:**

- **Modular Page Structure:** Each page consists of a main pane that takes up the full screen when the page is visited.
- **Widget Integration:** Pages can have widgets (e.g., side sheets, dialog boxes, context menus) that overlay the main content.
- **Integrated Gesture Handling:** Each widget can define its own gesture handler, creating a tight coupling between the widget and its interaction method.
- **Single Active Widget:** Only one widget can be active at any given time, ensuring a clear interaction hierarchy.
- **Scalability:** The system is designed to easily add new pages and widgets, with each widget managing its own gesture interactions.

---

## Class and Module Descriptions

### 1. **NavigationManager.swift**

**Purpose:** Manages the navigation path of the application, allowing for navigation between pages.

**Class: `NavigationManager`**

- **Description:** An `ObservableObject` that keeps track of the navigation path (`navigationPath`), which is an array of `AnyPage` instances.
- **Properties:**
  - `@Published var navigationPath: [AnyPage]`: The stack of pages representing the navigation history.
- **Methods:**
  - `func navigate(to page: AnyPage)`: Adds a new page to the navigation path, navigating forward.
  - `func navigateBack()`: Removes the last page from the navigation path, navigating back.
  - `func navigateToRoot()`: Clears the navigation path, returning to the root page.

**How it fits into the system:** The `NavigationManager` is the central component responsible for managing navigation state. It allows pages to instruct the app to navigate to other pages or back to previous ones.

---

### 2. **Page.swift**

**Purpose:** Defines the basic structure and behavior of a page in the application.

**Protocol: `Page`**

```swift
import SwiftUI

protocol Page: View {
    var id: UUID { get }
    var widgets: [any Widget] { get set }
    var navigationManager: NavigationManager? { get set }

    @ViewBuilder func makeMainContent() -> AnyView
}
```

- **Description:** A protocol that all pages conform to, representing a full-screen view with optional widget overlays.
- **Properties:**
  - `var id: UUID { get }`: A unique identifier for the page.
  - `var widgets: [any Widget] { get set }`: A list of widgets that can overlay the main content.
  - `var navigationManager: NavigationManager? { get set }`: A reference to the navigation manager.
- **Methods:**
  - `@ViewBuilder func makeMainContent() -> AnyView`: Creates the main content of the page.

**Extension of `Page`**

```swift
extension Page {
    var body: some View {
        ZStack {
            makeMainContent()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .edgesIgnoringSafeArea(.all)
                .gesture(combinedGesture())

            ForEach(widgets, id: \.id) { widget in
                if widget.isActive {
                    widget.view
                }
            }
        }
    }

    private func combinedGesture() -> AnyGesture<()> {
        // Collect all non-nil gestures from widgets
        let gestures = widgets.compactMap { $0.gesture }

        // Combine gestures as needed
        // ... gesture combination logic ...
    }
}
```

**How it fits into the system:** The `Page` protocol provides a standardized way to define full-screen pages with widget overlays. Each page's main content takes up the full screen, with widgets appearing on top when activated by their associated gestures.

---

### 3. **AnyPage.swift**

**Purpose:** Provides a type-erased wrapper for pages, allowing heterogeneous pages to be stored in collections.

**Struct: `AnyPage`**

```swift
import SwiftUI

struct AnyPage: Identifiable, View, Hashable {
    let id: UUID
    private let _view: AnyView

    init<P: Page>(_ page: P) {
        self.id = page.id
        self._view = AnyView(page)
    }

    var body: some View {
        _view
    }

    static func == (lhs: AnyPage, rhs: AnyPage) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
```

- **Description:** An `Identifiable`, `View`, and `Hashable` struct that wraps any `Page` instance.
- **Properties:**
  - `let id: UUID`: The unique identifier of the page.
  - `private let _view: AnyView`: The type-erased view of the page.
- **Initializer:**
  - `init<P: Page>(_ page: P)`: Initializes an `AnyPage` with a concrete `Page` instance.
- **Conformance:**
  - Implements `==` and `hash(into:)` for `Hashable`.
- **Body:**
  - `var body: some View`: Returns the stored `_view`.

**How it fits into the system:** `AnyPage` allows different types of pages to be stored in the `navigationPath` array of `NavigationManager`, enabling navigation between pages of different types.

---

### 4. **Widget.swift**

**Purpose:** Defines the basic structure of interactive overlay components and provides a base implementation.

**Protocol: `Widget`**

```swift
protocol Widget: Identifiable, ObservableObject {
    var id: UUID { get }
    var isActive: Bool { get }
    var view: AnyView { get }
    var gesture: AnyGesture<()>? { get }

    func setActive(_ active: Bool)
}
```

**Base Class: `BaseWidget`**

```swift
class BaseWidget: ObservableObject, Widget {
    var id: UUID = UUID()
    @Published private(set) var isActive: Bool = false

    var view: AnyView {
        fatalError("Must override view")
    }

    var gesture: AnyGesture<()>? { nil }

    func setActive(_ active: Bool) {
        self.isActive = active
    }
}
```

- **Description:** A protocol and base class combination that provides both interface definition and standard implementation for widgets.
- **Protocol Properties:**
  - `var id: UUID { get }`: A unique identifier for the widget
  - `var isActive: Bool { get }`: Read-only state of the widget's visibility
  - `var view: AnyView { get }`: The visual representation of the widget
  - `var gesture: AnyGesture<()>? { get }`: The gesture associated with this widget
- **Base Implementation Features:**
  - Standard UUID generation
  - Thread-safe state management with `@Published private(set)`
  - Default gesture handling (none)
  - Protected state modification through `setActive(_:)`

**How it fits into the system:** The Widget protocol defines the interface that all interactive overlays must implement, while BaseWidget provides a standard implementation of common functionality, reducing code duplication and ensuring consistent behavior across widgets.

---

### 5. **SideSheet.swift**

**Purpose:** A concrete implementation of a widget representing a full-height side sheet.

**Class: `SideSheet<Content: View>`**

```swift
class SideSheet<Content: View>: BaseWidget {
    let content: Content
    private let gestureHandler: DragGestureHandler

    // Standard colors and dimensions
    private let backgroundColor = Color(uiColor: .systemGray6)
    private let overlayColor = Color.black.opacity(0.5)
    private let sheetWidth: CGFloat = UIScreen.main.bounds.width * 0.85

    override var view: AnyView {
        // View implementation...
    }

    override var gesture: AnyGesture<()>? {
        gestureHandler.makeGesture()
    }
}
```

- **Description:** A widget that displays a full-height side sheet with custom content, inheriting standard widget behavior from BaseWidget.
- **Key Features:**
  - Inherits standard widget state management
  - Full-height design that extends edge to edge
  - Integrated gesture handling for show/hide
  - System-appropriate dark gray background
  - Semi-transparent overlay
  - Smooth animations
- **Properties:**
  - Inherits `isActive` and state management from BaseWidget
  - Custom view implementation
  - Dedicated gesture handler for drag interactions

**How it fits into the system:** SideSheet demonstrates how to build upon the BaseWidget class to create specialized widgets while maintaining consistent behavior patterns across the application.

---

### 6. **BookPage.swift**

**Purpose:** A concrete page representing a book, showcasing how to implement pages with widgets and gestures.

**Class: `BookPage`**

```swift
import SwiftUI

class BookPage: Page, ObservableObject {
    var id: UUID = UUID()
    var navigationManager: NavigationManager?
    @Published var widgets: [any Widget] = []
    @Published var gestures: [AnyGesture<()>] = []

    let title: String
    let author: String

    init(title: String, author: String, navigationManager: NavigationManager?) {
        self.title = title
        self.author = author
        self.navigationManager = navigationManager

        setupWidgetsAndGestures()
    }

    func makeMainContent() -> AnyView {
        AnyView(
            VStack {
                Text("Book Page")
                    .font(.largeTitle)
                Text("Title: \(title)")
                Text("Author: \(author)")
                Button("Go Back") {
                    navigationManager?.navigateBack()
                }
            }
        )
    }

    private func setupWidgetsAndGestures() {
        let sideSheet = SideSheet {
            VStack {
                Text("Book Details")
                    .font(.largeTitle)
                Text("Title: \(self.title)")
                Text("Author: \(self.author)")
                Button("Close") {
                    sideSheet.isActive = false
                }
            }
            .padding()
            .eraseToAnyView()
        }

        let dragGesture = AnyGesture(
            DragGesture(minimumDistance: 20)
                .onChanged { value in
                    if value.translation.width > 50 {
                        sideSheet.isActive = true
                    }
                }
                .map { _ in () }
        )

        self.widgets = [sideSheet]
        self.gestures = [dragGesture]
    }
}

extension View {
    func eraseToAnyView() -> AnyView {
        AnyView(self)
    }
}
```

- **Description:** A `Page` that displays book information and includes a side sheet widget.
- **Properties:**
  - `var id: UUID`: Unique identifier.
  - `var navigationManager: NavigationManager?`: Reference to the navigation manager.
  - `@Published var widgets: [any Widget]`: List of widgets associated with the page.
  - `@Published var gestures: [AnyGesture<()>]`: List of gestures associated with the page.
  - `let title: String`: The title of the book.
  - `let author: String`: The author of the book.
- **Initializer:**
  - `init(title: String, author: String, navigationManager: NavigationManager?)`: Initializes the page with book details and navigation manager.
  - Calls `setupWidgetsAndGestures()` to initialize widgets and gestures.
- **Methods:**
  - `func makeMainContent() -> AnyView`: Creates the main content view of the page.
  - `private func setupWidgetsAndGestures()`: Sets up the side sheet widget and the associated drag gesture.
- **Behavior:**
  - Displays book information.
  - Includes a side sheet that shows more details when a right drag gesture is detected.

**How it fits into the system:** `BookPage` demonstrates how to implement a page with widgets and gestures, following the protocols and structure defined in the system.

---

### 7. **DailyPage.swift**

**Purpose:** A concrete page representing daily information, showing how to implement a simple page without additional widgets.

**Struct: `DailyPage`**

```swift
import SwiftUI

struct DailyPage: Page {
    var id: UUID = UUID()
    var navigationManager: NavigationManager?
    var widgets: [any Widget] = []
    var gestures: [AnyGesture<()>] = []

    let date: Date

    init(date: Date, navigationManager: NavigationManager?) {
        self.date = date
        self.navigationManager = navigationManager
    }

    func makeMainContent() -> AnyView {
        AnyView(
            VStack {
                Text("Daily Page")
                    .font(.largeTitle)
                Text("Date: \(date.formatted(date: .long, time: .omitted))")
                Button("Go Back") {
                    navigationManager?.navigateBack()
                }
            }
        )
    }
}
```

- **Description:** A `Page` that displays daily information (e.g., date).
- **Properties:**
  - `var id: UUID`: Unique identifier.
  - `var navigationManager: NavigationManager?`: Reference to the navigation manager.
  - `var widgets: [any Widget]`: Empty list as there are no widgets.
  - `var gestures: [AnyGesture<()>]`: Empty list as there are no gestures.
  - `let date: Date`: The date to display.
- **Initializer:**
  - `init(date: Date, navigationManager: NavigationManager?)`: Initializes the page with a date and navigation manager.
- **Methods:**
  - `func makeMainContent() -> AnyView`: Creates the main content view of the page.
- **Behavior:**
  - Displays the date and provides a "Go Back" button to navigate back.

**How it fits into the system:** `DailyPage` shows a basic implementation of a page that doesn't include any widgets or gestures, illustrating the flexibility of the system.

---

### 8. **HomePage.swift**

**Purpose:** A concrete page serving as the entry point of the app, allowing navigation to other pages.

**Struct: `HomePage`**

```swift
import SwiftUI

struct HomePage: Page {
    var id: UUID = UUID()
    var navigationManager: NavigationManager?
    var widgets: [any Widget] = []
    var gestures: [AnyGesture<()>] = []

    init(navigationManager: NavigationManager?) {
        self.navigationManager = navigationManager
    }

    func makeMainContent() -> AnyView {
        AnyView(
            VStack {
                Text("Home Page")
                    .font(.largeTitle)
                Button("Go to Book Page") {
                    let bookPage = BookPage(title: "Sample Book", author: "John Doe", navigationManager: navigationManager)
                    navigationManager?.navigate(to: AnyPage(bookPage))
                }
                Button("Go to Daily Page") {
                    let dailyPage = DailyPage(date: Date(), navigationManager: navigationManager)
                    navigationManager?.navigate(to: AnyPage(dailyPage))
                }
            }
        )
    }
}
```

- **Description:** A `Page` that serves as the home screen, providing navigation options to other pages.
- **Properties:**
  - `var id: UUID`: Unique identifier.
  - `var navigationManager: NavigationManager?`: Reference to the navigation manager.
  - `var widgets: [any Widget]`: Empty list as there are no widgets.
  - `var gestures: [AnyGesture<()>]`: Empty list as there are no gestures.
- **Initializer:**
  - `init(navigationManager: NavigationManager?)`: Initializes the page with a navigation manager.
- **Methods:**
  - `func makeMainContent() -> AnyView`: Creates the main content view of the page.
- **Behavior:**
  - Displays options to navigate to `BookPage` and `DailyPage`.
  - Uses the `navigationManager` to navigate to selected pages.

**How it fits into the system:** `HomePage` acts as the starting point of the application, utilizing the `NavigationManager` to navigate to other pages, demonstrating how pages interact with the navigation system.

---

### 9. **ContentView.swift**

**Purpose:** The root view of the application that sets up the navigation stack and environment.

**Struct: `ContentView`**

```swift
import SwiftUI

struct ContentView: View {
    @StateObject var navigationManager = NavigationManager()

    var body: some View {
        NavigationStack(path: $navigationManager.navigationPath) {
            AnyPage(HomePage(navigationManager: navigationManager))
                .navigationDestination(for: AnyPage.self) { page in
                    page
                }
        }
    }
}
```

- **Description:** The main view of the app that initializes the navigation manager and sets up the navigation stack.
- **Properties:**
  - `@StateObject var navigationManager = NavigationManager()`: The shared navigation manager.
- **Body:**
  - Uses `NavigationStack` with `navigationManager.navigationPath`.
  - Starts with `AnyPage(HomePage(navigationManager: navigationManager))` as the root page.
  - Sets up navigation destinations for `AnyPage`.

**How it fits into the system:** `ContentView` sets up the necessary environment and provides the navigation infrastructure for the app, integrating the navigation manager and starting the navigation stack.

---

### 10. **GestureHandler.swift**

**Purpose:** Defines the protocol for handling widget-specific gestures.

**Protocol: `GestureHandler`**

```swift
protocol GestureHandler {
    var widget: any Widget { get }
    var debugText: String { get }
    var translation: CGPoint { get }

    func makeGesture() -> AnyGesture<()>
    func shouldHandleGesture(translation: CGPoint) -> Bool
}
```

- **Description:** A protocol that standardizes gesture handling for widgets.
- **Properties:**
  - `var widget: any Widget { get }`: The widget this handler controls
  - `var debugText: String { get }`: Debugging information about gesture state
  - `var translation: CGPoint { get }`: Current gesture translation
- **Methods:**
  - `func makeGesture()`: Creates the gesture recognizer
  - `func shouldHandleGesture(translation:)`: Validates gesture conditions

### 11. **DragGestureHandler.swift**

**Purpose:** Implements drag gesture handling for widgets.

**Class: `DragGestureHandler`**

```swift
class DragGestureHandler: ObservableObject, GestureHandler {
    let widget: any Widget
    private let direction: DragDirection
    private let threshold: CGFloat
    private let verticalLimit: CGFloat

    @Published private(set) var debugText: String
    @Published private(set) var translation: CGPoint

    enum DragDirection {
        case rightToLeft
        case leftToRight
    }
}
```

- **Description:** A concrete implementation of GestureHandler for drag gestures.
- **Features:**
  - Configurable drag direction
  - Customizable thresholds
  - Built-in debug information
  - Direction-specific validation

### 12. **BookPage.swift (Updated Implementation)**

**Purpose:** Demonstrates a page with widget and gesture integration.

**Implementation Structure:**

```swift
class BookPageViewModel: ObservableObject {
    @Published var widgets: [any Widget] = []

    private func setupWidgetsAndGestures() {
        let sheet = SideSheet {
            // Sheet content...
        }
        self.widgets = [sheet]  // Widget includes its own gesture
    }
}

struct BookPage: Page {
    var widgets: [any Widget] {
        get { viewModel.widgets }
        set { viewModel.widgets = newValue }
    }
}
```

- **Key Changes:**
  - Removed separate gesture handling
  - Widgets now manage their own gestures
  - Simplified widget setup
  - MVVM pattern for state management

---

## Architectural Patterns

### Widget-Gesture Coupling

The system now implements a tight coupling between widgets and their gestures:

1. **Encapsulation:**

   - Each widget defines its own gesture behavior
   - Gesture handling logic stays with the relevant widget
   - Clear ownership of interaction patterns

2. **Benefits:**

   - Reduced complexity in pages
   - Self-contained widget implementations
   - Easier to maintain and modify gesture behavior
   - Clear debugging path for gesture issues

3. **Implementation Pattern:**

```swift
class CustomWidget: Widget {
    private let gestureHandler: GestureHandler

    var gesture: AnyGesture<()>? {
        gestureHandler.makeGesture()
    }
}
```

### Debug Support

The system includes built-in debugging support for gesture interactions:

1. **Gesture Debugging:**

   - Real-time translation tracking
   - State change logging
   - Threshold validation reporting

2. **Implementation:**

```swift
protocol GestureHandler {
    var debugText: String { get }
    var translation: CGPoint { get }
}
```

---

## Best Practices

### Widget Implementation

When creating new widgets:

1. **Gesture Integration:**

   ```swift
   class NewWidget: Widget {
       private let gestureHandler: GestureHandler

       init() {
           self.gestureHandler = DragGestureHandler(
               widget: self,
               direction: .leftToRight
           )
       }

       var gesture: AnyGesture<()>? {
           gestureHandler.makeGesture()
       }
   }
   ```

2. **State Management:**
   - Use `private(set)` for `isActive`
   - Implement `setActive(_:)` for state changes
   - Consider side effects in state changes

### Page Implementation

When creating new pages:

1. **Widget Setup:**

   ```swift
   class PageViewModel: ObservableObject {
       @Published var widgets: [any Widget] = []

       func setupWidgets() {
           let widget = NewWidget()
           widgets = [widget]
       }
   }
   ```

2. **Best Practices:**
   - Use MVVM pattern for complex pages
   - Let widgets handle their own gestures
   - Keep main content full-screen
   - Consider widget interaction patterns

---

## How Modules Fit Together

- **Pages:** Each page conforms to the `Page` protocol, providing main content and optionally including widgets and gestures.
- **Widgets:** Widgets conform to the `Widget` protocol and represent interactive components that can be displayed on top of pages.
- **Gestures:** Gestures are associated with pages and can trigger widgets or other actions.
- **NavigationManager:** Manages the navigation between pages, allowing pages to navigate to other pages or navigate back.
- **AnyPage:** Allows for heterogeneous pages to be stored in the navigation path, enabling navigation between different types of pages.
- **ContentView:** Sets up the navigation stack and starts the application with the `HomePage`.

When a page is displayed, its main content is shown, and any gestures defined are active. If a gesture is recognized, it can activate a widget (e.g., a side sheet). Only one widget is active at a time, and it manages subsequent gestures until it is dismissed.

This design ensures modularity, scalability, and the ability to easily add new pages, widgets, and gestures as required in the future.

---

## Example Workflow

1. **App Launches:**

   - `ContentView` is initialized.
   - `NavigationManager` is created and injected into the environment.
   - `HomePage` is displayed as the root page.

2. **User Navigates to BookPage:**

   - User taps "Go to Book Page" on `HomePage`.
   - `HomePage` uses `navigationManager` to navigate to `BookPage`.
   - `BookPage` is pushed onto the navigation stack.

3. **User Triggers Side Sheet:**

   - On `BookPage`, the user performs a right drag gesture.
   - The gesture is recognized, and the side sheet widget is activated.
   - The side sheet slides in, displaying additional book details.

4. **User Dismisses Side Sheet:**

   - User taps outside the side sheet or presses the "Close" button.
   - The side sheet is deactivated and slides out.

5. **User Navigates Back:**

   - User presses "Go Back" on `BookPage`.
   - `BookPage` uses `navigationManager` to navigate back.
   - The app returns to `HomePage`.

---

## Scalability and Future Extensions

The system is designed to be modular and extensible:

- **Adding New Pages:** To add a new page type, create a new struct or class conforming to `Page`, implement `makeMainContent()`, and add any widgets or gestures as needed.
- **Adding New Widgets:** Create new classes conforming to `Widget` to represent different types of interactive components (e.g., dialogs, context menus).
- **Adding New Gestures:** Gestures can be directly added to the `gestures` array in a page, allowing for custom gesture recognition and handling.
- **Custom Navigation Actions:** Pages have access to the `NavigationManager`, allowing them to perform custom navigation actions (e.g., navigating to specific pages based on user input).

---

## Conclusion

This navigation and page management system provides a robust and scalable framework for building complex SwiftUI applications. By leveraging protocols and modular components, it allows for easy addition of new pages, widgets, and gestures, ensuring that the app can grow and adapt to future requirements.

**Benefits:**

- **Modularity:** Clear separation of concerns allows for individual components to be developed and tested in isolation.
- **Scalability:** New features can be added without significant changes to the existing codebase.
- **Maintainability:** The use of protocols and standard patterns simplifies code maintenance and readability.
- **User Experience:** The ability to manage navigation paths and interactive widgets enhances the user experience.

**Next Steps:**

- **Implement Additional Widgets and Gestures:** Expand the library of widgets and gestures to enhance functionality.
- **Customize UI Components:** Tailor the appearance of pages and widgets to match the app's design language.
- **Optimize Performance:** Ensure that the app performs efficiently, especially when dealing with complex pages and heavy content.
