import SwiftUI
import Charts

/// Vue courbe du total de pas hebdomadaire sur les 6 dernières semaines
struct WeeklyStepsTrendView: View {
    @EnvironmentObject var healthVM: HealthViewModel
    @State private var isLoaded = false

    /// Retourne les 6 dernières semaines (date de début lundi) et le total des pas
    private var weeklyData: [(weekStart: Date, total: Int)] {
        let cal = Calendar.current
        let today = Date()
        // Début de la semaine actuelle (lundi)
        guard let currentWeekStart = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)) else {
            return []
        }

        // Normaliser les clés des jours
        let normalizedData: [Date: Int] = Dictionary(uniqueKeysWithValues:
            healthVM.stepVM.stepsPerDay.map { (cal.startOfDay(for: $0.key), $0.value) }
        )

        return (-5...0).compactMap { offset -> (weekStart: Date, total: Int)? in
            guard let weekStart = cal.date(byAdding: .weekOfYear, value: offset, to: currentWeekStart),
                  let weekEnd   = cal.date(byAdding: .day, value: 6, to: weekStart) else {
                return nil
            }
            let total = normalizedData
                .filter { $0.key >= weekStart && $0.key <= weekEnd }
                .map(\.value)
                .reduce(0, +)
            return (weekStart: weekStart, total: total)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("📊 Pas hebdo – 6 dernières semaines")
                .font(.headline)
                .padding(.leading)

            if weeklyData.isEmpty {
                ProgressView("Chargement des données…")
                    .frame(height: 200)
                    .padding()
            } else {
                Chart {
                    ForEach(weeklyData, id: \.weekStart) { entry in
                        LineMark(
                            x: .value("Semaine", entry.weekStart),
                            y: .value("Total Pas", entry.total)
                        )
                        .interpolationMethod(.catmullRom)

                        PointMark(
                            x: .value("Semaine", entry.weekStart),
                            y: .value("Total Pas", entry.total)
                        )
                    }
                }
                .chartXScale(domain: weeklyData.first!.weekStart ... weeklyData.last!.weekStart)
                .chartXAxis {
                    AxisMarks(values: weeklyData.map(\.weekStart)) { value in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel {
                            if let date = value.as(Date.self) {
                                Text(shortWeekString(from: date))
                            }
                        }
                    }
                }
                .frame(height: 200)
                .padding(.horizontal)
            }
        }
        .onAppear {
            guard !isLoaded else { return }
            let cal = Calendar.current
            let endDate   = cal.startOfDay(for: Date())
            let startDate = cal.date(byAdding: .day, value: -42, to: endDate)!
            healthVM.stepVM.loadStepsData(range: .custom(start: startDate, end: endDate))
            isLoaded = true
        }
    }

    /// Format court pour début de semaine : "dd MMM"
    private func shortWeekString(from date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale.current
        f.dateFormat = "d MMM"
        return f.string(from: date)
    }
}

struct WeeklyStepsTrendView_Previews: PreviewProvider {
    static var previews: some View {
        WeeklyStepsTrendView()
            .environmentObject(sampleHealthVM)
    }

    private static var sampleHealthVM: HealthViewModel = {
        let vm = HealthViewModel()
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        for offset in 0..<42 {
            let date = cal.date(byAdding: .day, value: -offset, to: today)!
            vm.stepVM.stepsPerDay[date] = Int.random(in: 2000...10000)
        }
        return vm
    }()
}
