import SwiftUI

struct WeeklyRunningDistanceWidget: View {
    var distance: Double // En kilomètres

    var body: some View {
        VStack(spacing: 8) {
            Text("Cette semaine")
                .font(.caption)
                .foregroundColor(.secondary)

            Text("\(String(format: "%.1f", distance)) km")
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
