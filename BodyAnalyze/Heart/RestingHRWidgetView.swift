import SwiftUI

struct RestingHRWidgetView: View {
    let weeklyAverage: Double
    let referenceAverage: Double   // moyenne sur 30 jours pour comparaison

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("📉 Moyenne 7 jours")
                .font(.headline)

            Text("\(Int(weeklyAverage)) bpm")
                .font(.largeTitle)
                .bold()
                .foregroundColor(.blue)

            // Analyse rapide
            if weeklyAverage <= referenceAverage {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Bonne récupération")
                        .font(.subheadline)
                        .foregroundColor(.green)
                }
            } else if weeklyAverage > referenceAverage + 5 {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("Fatigue possible")
                        .font(.subheadline)
                        .foregroundColor(.orange)
                }
            } else {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.gray)
                    Text("Légère variation")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}
