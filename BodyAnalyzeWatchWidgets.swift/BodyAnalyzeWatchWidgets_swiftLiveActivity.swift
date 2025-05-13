//
//  BodyAnalyzeWidgets_swiftLiveActivity.swift
//  BodyAnalyzeWidgets.swift
//
//  Created by Lionel Barranco on 14/04/2025.
//
#if canImport(ActivityKit)
import ActivityKit
import WidgetKit
import SwiftUI

struct BodyAnalyzeWidgets_swiftAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct BodyAnalyzeWidgets_swiftLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: BodyAnalyzeWidgets_swiftAttributes.self) { context in
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

extension BodyAnalyzeWidgets_swiftAttributes {
    fileprivate static var preview: BodyAnalyzeWidgets_swiftAttributes {
        BodyAnalyzeWidgets_swiftAttributes(name: "World")
    }
}

extension BodyAnalyzeWidgets_swiftAttributes.ContentState {
    fileprivate static var smiley: BodyAnalyzeWidgets_swiftAttributes.ContentState {
        BodyAnalyzeWidgets_swiftAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: BodyAnalyzeWidgets_swiftAttributes.ContentState {
         BodyAnalyzeWidgets_swiftAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: BodyAnalyzeWidgets_swiftAttributes.preview) {
   BodyAnalyzeWidgets_swiftLiveActivity()
} contentStates: {
    BodyAnalyzeWidgets_swiftAttributes.ContentState.smiley
    BodyAnalyzeWidgets_swiftAttributes.ContentState.starEyes
}
#endif
