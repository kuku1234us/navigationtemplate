//
//  NavWidgetLiveActivity.swift
//  NavWidget
//
//  Created by Mac14 on 12/13/24.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct NavWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct NavWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: NavWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension NavWidgetAttributes {
    fileprivate static var preview: NavWidgetAttributes {
        NavWidgetAttributes(name: "World")
    }
}

extension NavWidgetAttributes.ContentState {
    fileprivate static var smiley: NavWidgetAttributes.ContentState {
        NavWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: NavWidgetAttributes.ContentState {
         NavWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: NavWidgetAttributes.preview) {
   NavWidgetLiveActivity()
} contentStates: {
    NavWidgetAttributes.ContentState.smiley
    NavWidgetAttributes.ContentState.starEyes
}
