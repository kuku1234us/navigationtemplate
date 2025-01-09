# Overview

The Activity Management functionality of the iOSWiz app is designed to help users log, monitor, and manage their daily activities efficiently. This document provides an in-depth look at the features and capabilities of the Activities Management section and the NavWidget. Users can track activities such as waking, sleeping, eating, and exercising, ensuring a comprehensive view of their daily routines. The integration with the Obsidian iCloud Vault allows for seamless data synchronization and accessibility across devices, enhancing the overall user experience.

---

# Main App - Activities Management Page

The Activities Page is the primary interface in the iOSWiz App for tracking and managing daily activities. It provides a visual and interactive experience for reviewing past actions and logging new ones.

## Key Features

1. **Header Section**:    
    - **Title**: Displays "Activities" at the top of the page.        
    - **Time Indicators**:        
        - **Conscious State Timer**: Shows the elapsed time since the last logged wake or sleep activity.            
        - **Meal Timer**: Indicates the elapsed time since the last logged meal.
            
2. **Activity List**:    
    - A chronological log of activities, sorted in descending order (most recent at the top).        
    - Each entry includes:        
        - **Time**: The time the activity occurred.            
        - **Date**: The date of the activity.            
        - **Activity Icon**: A visual representation of the activity type (e.g., wake, sleep, meal, exercise).
            
3. **Activity Menu**:    
    - Located on the right side of the activity list.        
    - Contains four buttons for quick activity logging:        
        1. **Wake**
        2. **Sleep**            
        3. **Meal**            
        4. **Exercise**            
    - Users can tap these buttons to log the corresponding activity instantly.
        
4. **Data Synchronization**:    
    - All logged activities are stored in the Obsidian iCloud Vault, ensuring seamless syncing across devices.        

---

# NavWidget (Home Screen Integration)

The iOSWiz NavWidget extends the app's functionality to the iOS home screen, providing users with quick access to activity logging and real-time insights. This section outlines the key features, integration mechanisms, and data flow processes that enable seamless interaction between the widget and the main app.

## Key Features

1. **Activity Buttons Pane**:
   - The widget includes four buttons for quick activity logging: Sleep, Wake, Meal, and Exercise.
   - Users can log activities directly from the home screen, enhancing convenience and accessibility.
   - Fast response time: When the user taps an activity button, getTimeline() of the widget creates only two Timeline entries to allow immediate rerendering of the widget. When getTimeline() is invoked again, it creates a longer timeline with 60 entries as response time is no longer a factor.

2. **Time Indicators**:
   - The widget displays two time indicators:
     - **Conscious State Timer**: Shows the elapsed time since the last logged wake or sleep activity.
     - **Meal Timer**: Indicates the elapsed time since the last logged meal.
     - Precomputation: The getTimeline() method precomputes all the time indicator text at the time of generation. Subsequent renderings displays the precomputed text, allowing the most efficient rendering.

## Integration with User.Defaults

Due to Apple's sandbox policy, which may restrict a widget's access to iCloud and other resources, the NavWidget does not directly access hte iCloud_Vault. Instead, it uses `User.Defaults` to temporarily cache activity updates. When the main app is launched, it processes the `PendingActivities` queue and writes the activities to the iCloud_Vault. This integration involves two key structures:

1. **Last Known Activities State**:
   - Stores the latest timestamp for each activity type (Sleep, Wake, Meal, Exercise) in a dictionary format.
   - Provides a quick lookup for time calculations and ensures the widget displays the most recent activity state.
   - User.Defaults Key: `LastKnownActivities`
   - Type: Dictionary with ActivityType keys and Unix timestamp values
   - Structure:
     ```json
     {
       "sleep": 1703123456,    // Unix timestamp of last sleep
       "wake": 1703123789,     // Unix timestamp of last wake
       "meal": 1703123555,     // Unix timestamp of last meal
       "exercise": 1703122222  // Unix timestamp of last exercise
     }
     ```
     - Maximum of one entry for each activity type (currently there are 4 activity types)

2. **Pending Activities Queue**:
   - Maintains a FIFO queue of activities logged through the widget, awaiting processing by the main app.
   - Ensures no data loss during iCloud access failures by acting as a temporary storage solution.
   - User.Defaults Key: `PendingActivities`
   - Type: JSON-encoded array of ActivityItems
   - Structure:
     ```json
     [
       {
         "activityType": "sleep",
         "activityTime": 1703123456
       },
       {
         "activityType": "meal",
         "activityTime": 1703123789
       }
     ]
     ```

## Data Flow Process

1. **Widget Action**:
   - When a user logs an activity via the widget, it is added to the `PendingActivities` queue.
   - The widget UI updates using the combined state of `LastKnownActivities` and `PendingActivities`.
   - A new Timeline is generated. The widget is rerendered immediately to reflect the new activity state and time indicators.

2. **Main App Processing**:
   - Upon launch or becoming active, the main app processes the `PendingActivities` queue.
   - Activities are written to the iCloud Vault.
   - Processed items are cleared from the queue to maintain data consistency.

## Widget Rendering and Rerendering

The NavWidget uses a dual update system to ensure that activity data is current and accurately displayed. This system addresses the limitations of the widget environment, such as the inability to observe changes in UserDefaults or use NotificationCenter observers.

### Timeline-Based Updates

The `getTimeline()` function is central to the widget's update mechanism. It generates timeline entries that dictate when and how the widget updates its display:

- **Activity Data Loading**: Instead of accessing the `ActivityStack` directly, the widget uses values stored in `User.Defaults`, such as `LastKnownActivities`, to load the latest activity data. This approach avoids direct access to the iCloud Vault, which is restricted in the widget environment.

- **Timeline Entry Generation**: For non-user-triggered updates, `getTimeline()` generates 60 timeline entries. This process can be lengthy but ensures the widget remains updated efficiently over an extended period.

- **Completion**: Passes the generated timeline, containing all entries and their refresh policies, to the completion handler, ensuring scheduled updates.

### User-Initiated Updates

User-initiated updates occur when a user taps one of the activity buttons in the Activities Pane. This action triggers an AppIntent that invokes the `getTimeline()` function. To allow for fast response time, `getTimeline()` generates only two timeline entries during this process. This ensures that the widget is rerendered immediately to reflect the new activity state and time indicators. Subsequent invocations of `getTimeline()` will revert to generating the regular 60-entry timeline, maintaining the widget's update schedule.

### Updates Triggered by Main App

The `ActivityStack.rerenderWidget()` method is used to trigger immediate widget refreshes when changes occur in the main app, such as logging a new activity, editing, or removing an activity. This method calls `WidgetCenter.shared.reloadAllTimelines()` to update the widget display without delay, maintaining UI consistency between the app and the widget.

This three-factor approach ensures that the widget remains current with user actions and regularly updates its display, providing users with accurate and timely information.

---

# Data Storage and Syncing

iOSWiz uses the Obsidian iCloud Vault as the backend for storing activity logs. This setup ensures that:

1. **Centralized Storage**:    
    - Activity data is saved in iCloud_Vault ensuring data is synced across devices and securely persisted.    
    - Data changes made in the iOSWiz app or widget are propagated across devices via iCloud.        
    - Any updates in the Obsidian vault are automatically reflected in the app.
        
2. **Vault Selection**:    
    - The main app provides a settings screen that allows users to navigate to their iCloud Vault and select the desired folder.        
    - The app creates a bookmark to the selected vault folder, enabling future read/write operations.

---

# Usage Workflow

1. **Logging an Activity**:    
    - Tap the corresponding button (Wake, Sleep, Meal, Exercise) on the Activities page or the NavWidget to log an activity.        
    - The app timestamps the activity and saves it in the iCloud Vault.
        
2. **Viewing Logged Activities**:    
    - Open the Activities page to see a detailed list of past activities.        
    - Use the activity icons to quickly identify the type of activity.
        
3. **Home Screen Access**:    
    - Use the NavWidget to check the elapsed time since the last activity or to log new activities without opening the app.
