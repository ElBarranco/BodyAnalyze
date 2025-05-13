import SwiftUI
import WidgetKit

// MARK: - Widget View (UI)
struct BodyBatteryWidgetView: View {
    var score: Double

    var body: some View {
        ZStack {
            ArcShape(percent: 1.0)
                .stroke(Color.gray.opacity(0.2), lineWidth: 8)

            ArcShape(percent: min(score / 10.0, 1.0))
                .stroke(batteryColor(), style: StrokeStyle(lineWidth: 8, lineCap: .round))

            VStack {
                Text("⚡️")
                    .font(.caption2)
                Text(String(format: "%.1f", score))
                    .font(.headline)
                    .bold()
            }
        }
        .containerBackground(for: .widget) {
            Color.black
        }
    }

    func batteryColor() -> Color {
        switch score {
        case 0..<3: return .red
        case 3..<7: return .orange
        default: return .green
        }
    }
}

// MARK: - ArcShape
struct ArcShape: Shape {
    var percent: Double = 1.0

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let radius = rect.width / 2
        let center = CGPoint(x: rect.midX, y: rect.maxY)
        let startAngle = Angle.degrees(180)
        let endAngle = Angle.degrees(180 + percent * 180)
        path.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        return path
    }
}

// MARK: - Entry
struct BodyBatteryEntry: TimelineEntry {
    let date: Date
    let score: Double
}

// MARK: - Provider
struct BodyBatteryProvider: TimelineProvider {
    func placeholder(in context: Context) -> BodyBatteryEntry {
        BodyBatteryEntry(date: Date(), score: 6.5)
    }

    func getSnapshot(in context: Context, completion: @escaping (BodyBatteryEntry) -> Void) {
        let entry = BodyBatteryEntry(date: Date(), score: 6.5)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BodyBatteryEntry>) -> Void) {
        let defaults = UserDefaults(suiteName: "group.Octopy.BodyAnalyze")
        let score = defaults?.double(forKey: "bodyBatteryScore") ?? 5.0

        let entry = BodyBatteryEntry(date: Date(), score: score)
        let nextUpdate = Date().addingTimeInterval(1800)
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Entry View
struct BodyBatteryWidgetEntryView: View {
    var entry: BodyBatteryEntry

    var body: some View {
        BodyBatteryWidgetView(score: entry.score)
    }
}

// MARK: - Widget declaration (sans @main ici)
struct BodyBatteryWatchWidget: Widget {
    let kind = "BodyBatteryWatchWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BodyBatteryProvider()) { entry in
            BodyBatteryWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Body Battery – Watch")
        .description("Forme du jour")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}
