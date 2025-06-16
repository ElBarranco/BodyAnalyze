import SwiftUI
import Charts

struct RestingHeartRateChartView: View {
    @ObservedObject var analyzer: RestingHeartRateAnalyzer

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 📈 Courbe allégée sur 14 jours
            Chart {
                // 🔵 Courbe FC repos (Line + Points)
                ForEach(analyzer.sortedEntries.suffix(14), id: \.id) { entry in
                    LineMark(
                        x: .value("Date", entry.date),
                        y: .value("FC Repos", Double(entry.bpm))
                    )
                    .interpolationMethod(.monotone)
                    .foregroundStyle(Color.blue)
                    .lineStyle(StrokeStyle(lineWidth: 2))

                    PointMark(
                        x: .value("Date", entry.date),
                        y: .value("FC Repos", Double(entry.bpm))
                    )
                    .symbol(.circle)
                    .foregroundStyle(Color.blue)
                }

                // ➖ Moyenne 7 jours
                RuleMark(y: .value("Moyenne 7j", analyzer.averageLast7Days))
                    .foregroundStyle(Color.gray)
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 5)) { value in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.day().month())
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .frame(height: 250)

            if let last = analyzer.sortedEntries.last {
                Text("Dernier relevé : \(last.bpm) bpm")
                    .font(.footnote)
            }
        }
        .padding()
    }
}
