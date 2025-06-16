import SwiftUI
import Charts

struct TrainingLoadChartView: View {
    @EnvironmentObject var healthVM: HealthViewModel
    var isSimulated: Bool = false

    struct TrainingLoadPoint: Identifiable {
        let id = UUID()
        let date: Date
        let value: Double
    }

    var body: some View {
        let days = getLast90Days()
        let data = days.map { date in
            TrainingLoadPoint(
                date: date,
                value: isSimulated
                    ? simulateLoad(for: date)
                    : healthVM.trainingVM.calculateTrainingLoad(for: date)
            )
        }

        let nonZeroData = data.filter { $0.value > 0 }
        let moyenne = isSimulated
            ? nonZeroData.map(\.value).reduce(0, +) / Double(nonZeroData.count)
            : healthVM.trainingVM.getAverageEPOCOverLastWeeks()

        let zoneMin = max(moyenne * 0.8, 1)
        let zoneMax = moyenne * 1.2

        VStack(alignment: .leading, spacing: 12) {
            Text("📊 Training Load - 90 jours")
                .font(.title2)
                .bold()

            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    Chart {
                        // 🟩 Zone verte optimale
                        RectangleMark(
                            xStart: .value("Start", data.first?.date ?? Date()),
                            xEnd: .value("End", data.last?.date ?? Date()),
                            yStart: .value("Min", zoneMin),
                            yEnd: .value("Max", zoneMax)
                        )
                        .foregroundStyle(.green.opacity(0.2))

                        // 📈 Courbe blanche + points
                        ForEach(data) { point in
                            LineMark(
                                x: .value("Date", point.date),
                                y: .value("Load", point.value)
                            )
                            .interpolationMethod(.monotone)
                            .foregroundStyle(.white)
                            .lineStyle(StrokeStyle(lineWidth: 2))

                            PointMark(
                                x: .value("Date", point.date),
                                y: .value("Load", point.value)
                            )
                            .foregroundStyle(.white)
                        }
                    }
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day, count: 7)) { value in
                            AxisGridLine()
                            AxisValueLabel(format: .dateTime.day().month(), centered: true)
                        }
                    }
                    .chartYAxis {
                        AxisMarks()
                    }
                    .frame(width: CGFloat(data.count) * 20, height: 300)
                    .id("scrollChart")
                }
                .onAppear {
                    // Auto scroll vers les jours récents
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation {
                            proxy.scrollTo("scrollChart", anchor: .trailing)
                        }
                    }
                }
            }

            // ✅ Bloc d'analyse automatique
            Text(analysisMessage(todayLoad: getTodayLoad(), average: moyenne))
                .font(.footnote)
                .foregroundColor(.secondary)
                .padding(.horizontal)
                .padding(.top, 4)
        }
        .padding()
        .background(Color.black)
        .cornerRadius(12)
    }

    private func getLast90Days() -> [Date] {
        let calendar = Calendar.current
        return (0..<90)
            .compactMap { calendar.date(byAdding: .day, value: -$0, to: Date()) }
            .map { calendar.startOfDay(for: $0) }
            .reversed()
    }

    private func simulateLoad(for date: Date) -> Double {
        let dayOffset = Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0
        return 400 + 500 * sin(Double(dayOffset) / 3.0)
    }

    private func getTodayLoad() -> Double {
        let today = Calendar.current.startOfDay(for: Date())
        return isSimulated
            ? simulateLoad(for: today)
            : healthVM.trainingVM.calculateTrainingLoad(for: today)
    }

    private func analysisMessage(todayLoad: Double, average: Double) -> String {
        if todayLoad > average * 1.3 {
            return "🔺 Charge élevée aujourd’hui. Priorise la récupération demain si tu ressens de la fatigue."
        } else if todayLoad < average * 0.5 {
            return "📉 Charge faible comparée à ton rythme habituel. Un peu d’intensité pourrait être bénéfique."
        } else {
            return "✅ Journée équilibrée, tu restes dans une dynamique de progression !"
        }
    }
}
