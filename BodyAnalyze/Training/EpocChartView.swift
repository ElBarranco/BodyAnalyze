import SwiftUI
import Charts

struct EpocChartView: View {
    @EnvironmentObject var healthVM: HealthViewModel
    @State private var currentWeekOffset = 0
    private let weekOffsets = Array(-5...0) // Affiche les 6 dernières semaines

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 🗓️ Titre avec date de début de semaine
            Text("🔥 Semaine du \(formattedWeekStartDate(for: currentWeekOffset))")
                .font(.headline)
                .padding(.leading)

            // 📊 Graphique swipeable
            TabView(selection: $currentWeekOffset) {
                ForEach(weekOffsets, id: \.self) { offset in
                    EpocWeekChartView(offset: offset)
                        .tag(offset)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .frame(height: 260)

            // 🏷️ Label dynamique
            Text(currentWeekOffset == 0
                  ? "Semaine actuelle"
                  : "Semaine \(abs(currentWeekOffset)) avant")
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.leading)
        }
        .padding(.top)
    }

    /// 🔁 Affiche la date de début de semaine selon l'offset
    private func formattedWeekStartDate(for offset: Int) -> String {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let target = cal.date(byAdding: .weekOfYear, value: offset, to: today)!
        let monday = cal.startOfWeek(for: target)

        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateStyle = .medium

        return formatter.string(from: monday)
    }
}
