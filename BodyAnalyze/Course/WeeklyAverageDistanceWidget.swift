import SwiftUI

struct WeeklyAverageDistanceWidget: View {
    var averageDistance: Double // En kilomètres

    var body: some View {
        VStack(spacing: 8) {
            Text("Moyenne hebdo (6 sem.)")
                .font(.caption)
                .foregroundColor(.secondary)

            Text("\(String(format: "%.1f", averageDistance)) km")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, minHeight: 100)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}
