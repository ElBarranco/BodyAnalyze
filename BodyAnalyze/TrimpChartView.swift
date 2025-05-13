import SwiftUI
import Charts

struct TrimpChartView: View {
    @EnvironmentObject var healthVM: HealthViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("📊 TRIMP – Charge d'entraînement de la semaine")
                .font(.headline)

            let trimpData = healthVM.trainingVM.trimpPerDay

            if trimpData.isEmpty {
                Text("Chargement des données TRIMP...")
                    .foregroundColor(.gray)
            } else {
                Chart {
                    ForEach(sortedTRIMPDays(), id: \.self) { date in
                        let score = trimpData[date] ?? 0
                        BarMark(
                            x: .value("Jour", shortDayString(from: date)),
                            y: .value("TRIMP", score)
                        )
                        .foregroundStyle(
                            score > 300 ? .red :
                            score > 200 ? .orange :
                            score > 100 ? .green :
                            .blue
                        )
                    }
                }
                .frame(height: 200)
            }
        }
    }

    // Génère les 7 derniers jours, arrondis à minuit
    func sortedTRIMPDays() -> [Date] {
        let calendar = Calendar.current
        return (0...6)
            .compactMap { calendar.date(byAdding: .day, value: -$0, to: Date()) }
            .map { calendar.startOfDay(for: $0) }
            .sorted()
    }

    // Format court du jour : LUN, MAR, MER...
    func shortDayString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }
}
