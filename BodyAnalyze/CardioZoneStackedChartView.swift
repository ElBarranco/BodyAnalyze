import SwiftUI

struct CardioZoneStackedChartView: View {
    let weeklyZones: [String: [Int: TimeInterval]] // clé = semaine, valeur = [zone: durée en sec]

    private let zoneColors: [Int: Color] = [
        2: .green,
        3: .blue,
        4: .purple,
        5: .red
    ]

    var body: some View {
        let sortedWeeks = weeklyZones.keys.sorted() // tri par label (Semaine 14, 15...)
        let maxTotal = weeklyZones.values.map { $0.values.reduce(0, +) }.max() ?? 1

        VStack(alignment: .leading) {
            Text("⏱ Temps passé par zone cardio (semaine)")
                .font(.headline)

            HStack(alignment: .bottom, spacing: 16) {
                ForEach(sortedWeeks, id: \.self) { week in
                    let zoneData = weeklyZones[week] ?? [:]
                    let total = zoneData.values.reduce(0, +)

                    VStack(spacing: 4) {
                        // Valeur totale en haut
                        Text("\(Int(total / 60)) min")
                            .font(.caption2)

                        // Barre empilée
                        ZStack(alignment: .bottom) {
                            VStack(spacing: 0) {
                                ForEach([2, 3, 4, 5], id: \.self) { zone in
                                    let duration = zoneData[zone] ?? 0
                                    let height = CGFloat(duration / maxTotal) * 150

                                    Rectangle()
                                        .fill(zoneColors[zone] ?? .gray)
                                        .frame(height: height)
                                }
                            }
                        }
                        .frame(width: 24)
                        .cornerRadius(4)

                        // Label semaine
                        Text(week)
                            .font(.caption2)
                            .rotationEffect(.degrees(-20))
                            .frame(width: 40)
                    }
                }
            }
            .frame(height: 160)

            // 🧾 Légende
            HStack(spacing: 20) {
                ForEach([2, 3, 4, 5], id: \.self) { zone in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(zoneColors[zone] ?? .gray)
                            .frame(width: 10, height: 10)
                        Text("Zone \(zone)")
                            .font(.caption)
                    }
                }
            }
            .padding(.top, 8)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 1)
    }
}
