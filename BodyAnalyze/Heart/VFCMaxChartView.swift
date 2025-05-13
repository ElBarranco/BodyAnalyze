import SwiftUI
import Charts

struct VFCMaxChartView: View {
    @EnvironmentObject var healthVM: HealthViewModel
    @State private var currentWeekOffset = 0
    private let weekOffsets = Array(-4...0)

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("🧘‍♂️ VFC Max/Min – Suivi de récupération")
                .font(.headline)
                .padding(.leading)

            TabView(selection: $currentWeekOffset) {
                ForEach(weekOffsets, id: \.self) { offset in
                    VFCWeekChartView(offset: offset)
                        .tag(offset)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .frame(height: 260)

            Text(currentWeekOffset == 0
                 ? "Semaine actuelle"
                 : "Semaine \(abs(currentWeekOffset)) avant")
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.leading)
        }
        .padding(.top)
    }
}

private struct VFCWeekChartView: View {
    @EnvironmentObject var healthVM: HealthViewModel
    let offset: Int

    private var days: [Date] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let weekday = cal.component(.weekday, from: today)
        let daysFromMonday = (weekday + 5) % 7
        guard
            let startOfThisWeek = cal.date(byAdding: .day, value: -daysFromMonday, to: today),
            let startOfTarget = cal.date(byAdding: .weekOfYear, value: offset, to: startOfThisWeek)
        else {
            return []
        }
        return (0...6).map { cal.date(byAdding: .day, value: $0, to: startOfTarget)! }
    }

    private var domainRange: ClosedRange<Date> {
        if let first = days.first, let last = days.last {
            return first...last
        } else {
            let today = Calendar.current.startOfDay(for: Date())
            return today...today
        }
    }

    private var maxData: [(Date, Double)] {
        days
            .map { date in (date, healthVM.heartVM.vfcMaxPerDay[date] ?? Double.nan) }
            .filter { $0.1.isFinite }
    }

    private var minData: [(Date, Double)] {
        days
            .map { date in (date, healthVM.heartVM.vfcMinPerDay[date] ?? Double.nan) }
            .filter { $0.1.isFinite }
    }

    private var averageMax: Double {
        guard !maxData.isEmpty else { return 0 }
        return maxData.map(\.1).reduce(0, +) / Double(maxData.count)
    }

    var body: some View {
        Chart {
            // Série Max
            ForEach(maxData, id: \.0) { date, vfc in
                LineMark(x: .value("Jour", date),
                         y: .value("VFC", vfc))
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 3))
                    .foregroundStyle(by: .value("Type", "Max"))

                PointMark(x: .value("Jour", date),
                          y: .value("VFC", vfc))
                    .symbolSize(30)
                    .foregroundStyle(by: .value("Type", "Max"))
                    .annotation(position: .top) {
                        Text(String(format: "%.0f", vfc))
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
            }

            // Série Min
            ForEach(minData, id: \.0) { date, vfc in
                LineMark(x: .value("Jour", date),
                         y: .value("VFC", vfc))
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    .foregroundStyle(by: .value("Type", "Min"))

                PointMark(x: .value("Jour", date),
                          y: .value("VFC", vfc))
                    .symbolSize(20)
                    .foregroundStyle(by: .value("Type", "Min"))
                    .annotation(position: .top) {
                        Text(String(format: "%.0f", vfc))
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
            }

            // Moyenne Max
            RuleMark(y: .value("Moyenne Max", averageMax))
                .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
                .foregroundStyle(.gray)
        }
        .chartXScale(domain: domainRange)
        .chartXAxis {
            AxisMarks(values: days) { _ in
                AxisGridLine()
                AxisTick()
                AxisValueLabel(format: .dateTime.weekday(.abbreviated))
            }
        }
        .chartForegroundStyleScale([
            "Max": .blue,
            "Min": .orange
        ])
        .chartOverlay { _ in Rectangle().fill(.clear) } // ✅ Désactive les interactions longues
        .frame(height: 200)
    }
}

#Preview {
    VFCMaxChartView()
        .environmentObject(HealthViewModel())
}
