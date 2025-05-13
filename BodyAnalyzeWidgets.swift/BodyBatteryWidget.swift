import SwiftUI
import WidgetKit

// MARK: - Arc Shape
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

// MARK: - Widget View (UI)
struct BodyBatteryWidgetView: View {
    var score: Double

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let arcWidth: CGFloat = 12
            let batteryPercent = min(score / 10.0, 1.0)

            ZStack {
                ArcShape(percent: 1.0)
                    .stroke(Color.gray.opacity(0.15), lineWidth: arcWidth)

                ArcShape(percent: batteryPercent)
                    .stroke(batteryColor(), style: StrokeStyle(lineWidth: arcWidth, lineCap: .round))

                VStack {
                    Text("⚡️")
                        .font(.caption)
                    Text(String(format: "%.1f", score))
                        .font(.title2)
                        .bold()
                }
            }
            .padding(arcWidth)
            .frame(width: size.width, height: size.height)
            .containerBackground(for: .widget) {
                Color(.systemBackground)
            }
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

// MARK: - Timeline Entry
struct BodyBatteryEntry: TimelineEntry {
    let date: Date
    let score: Double
}

// MARK: - Timeline Provider
struct BodyBatteryProvider: TimelineProvider {
    func placeholder(in context: Context) -> BodyBatteryEntry {
        BodyBatteryEntry(date: Date(), score: 6.5)
    }

    func getSnapshot(in context: Context, completion: @escaping (BodyBatteryEntry) -> Void) {
        completion(BodyBatteryEntry(date: Date(), score: 6.5))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BodyBatteryEntry>) -> Void) {
        let defaults = UserDefaults(suiteName: "group.Octopy.BodyAnalyze")
        let score = defaults?.double(forKey: "bodyBatteryScore") ?? 5.0

        let entry = BodyBatteryEntry(date: Date(), score: score)
        let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(60 * 60)))
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

// MARK: - Widget Declaration
struct BodyBatteryWidget: Widget {
    let kind: String = "BodyBatteryWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BodyBatteryProvider()) { entry in
            BodyBatteryWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Body Battery")
        .description("Une jauge de forme du jour.")
        .supportedFamilies([.systemSmall, .accessoryCircular, .accessoryRectangular])
    }
}

// MARK: - Preview
struct BodyBatteryWidget_Previews: PreviewProvider {
    static var previews: some View {
        BodyBatteryWidgetEntryView(entry: BodyBatteryEntry(date: Date(), score: 8.4))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
