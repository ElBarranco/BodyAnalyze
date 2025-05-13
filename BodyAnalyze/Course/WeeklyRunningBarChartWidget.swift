import SwiftUI
import Charts

struct WeeklyRunningBarChartWidget: View {
    var weeklyDistances: [WeekDistance]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Kilomètres sur 6 semaines")
                .font(.caption)
                .foregroundColor(.secondary)

            Chart(weeklyDistances) { week in
                BarMark(
                    x: .value("Semaine", week.label),
                    y: .value("Distance", week.distance)
                )
                .foregroundStyle(Color.blue)
                .cornerRadius(4)
            }
            .frame(height: 120)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// Modèle pour une semaine
struct WeekDistance: Identifiable {
    let id = UUID()
    let label: String  // Ex: "S-6", "S-5", ..., "S-1"
    let distance: Double
}
