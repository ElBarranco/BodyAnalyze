import SwiftUI

struct RestingHRTrendWidgetView: View {
    let average48h: Double
    let average7d: Double

    var delta: Double {
        average48h - average7d
    }

    var interpretation: (icon: String, text: String, color: Color) {
        if delta <= -2 {
            return ("checkmark.seal.fill", "Excellente récupération", .green)
        } else if delta >= 3 {
            return ("exclamationmark.triangle.fill", "Fatigue ou stress possible", .orange)
        } else {
            return ("info.circle.fill", "Légère variation", .gray)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("📊 FC repos : 48h vs 7j")
                .font(.headline)

            HStack {
                VStack(alignment: .leading) {
                    Text("48h : \(Int(average48h)) bpm")
                    Text("7j : \(Int(average7d)) bpm")
                }
                .font(.subheadline)

                Spacer()

                Image(systemName: interpretation.icon)
                    .foregroundColor(interpretation.color)
                    .font(.title2)
            }

            // 🧠 Légende en-dessous, centrée et compacte
            Text(interpretation.text)
                .font(.footnote)
                .foregroundColor(interpretation.color)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}
