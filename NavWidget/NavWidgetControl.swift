//
//  NavWidgetControl.swift
//  NavWidget
//
//  Created by Mac14 on 12/13/24.
//

import AppIntents
import SwiftUI
import WidgetKit
import NavTemplateShared

struct NavWidgetControl: ControlWidget {
    static let kind: String = "us.kothreat.NavTemplate.NavWidget"

    var body: some ControlWidgetConfiguration {
        AppIntentControlConfiguration(
            kind: Self.kind,
            provider: Provider()
        ) { value in
            ControlWidgetToggle(
                "Start Timer",
                isOn: value.isRunning,
                action: StartTimerIntent(value.name)
            ) { isRunning in
                Label(isRunning ? "On" : "Off", systemImage: "timer")
            }
        }
        .displayName("Timer")
        .description("A an example control that runs a timer.")
    }
}

extension NavWidgetControl {
    struct Value {
        var isRunning: Bool
        var name: String
    }

    struct Provider: AppIntentControlValueProvider {
        func previewValue(configuration: TimerConfiguration) -> Value {
            NavWidgetControl.Value(isRunning: false, name: configuration.timerName)
        }

        func currentValue(configuration: TimerConfiguration) async throws -> Value {
            let isRunning = true // Check if the timer is running
            return NavWidgetControl.Value(isRunning: isRunning, name: configuration.timerName)
        }
    }
}

struct TimerConfiguration: ControlConfigurationIntent {
    static let title: LocalizedStringResource = "Timer Name Configuration"

    @Parameter(title: "Timer Name", default: "Timer")
    var timerName: String
}

struct StartTimerIntent: SetValueIntent {
    static var title: LocalizedStringResource = "Start Timer"
    static var description: LocalizedStringResource = "Controls the timer"
    static var openAppWhenRun: Bool = true
    
    @Parameter(title: "Timer Name")
    var name: String
    
    @Parameter(title: "Timer is running")
    var value: Bool
    
    init() {}
    
    init(_ name: String) {
        self.name = name
        self.value = true  // Start the timer
    }
    
    func perform() async throws -> some IntentResult {
        print("Starting timer: \(name), value: \(value)")
        // Here we could start a timer or perform other actions
        return .result(value: "Timer Started")
    }
}
