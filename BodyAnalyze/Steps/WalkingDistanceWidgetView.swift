// WalkingDistanceWidgetView.swift
// BodyAnalyze
// Created by Lionel Barranco on 12/05/2025.

import SwiftUI

/// Widget affichant la distance parcourue à pied (course / marche / rando) par semaine
struct WalkingDistanceWidgetView: View {
    @EnvironmentObject var healthVM: HealthViewModel

    /// Récupère la distance de la semaine en cours, en comparant par granularité « semaine »
    private var lastWeekKm: Double {
        let cal = Calendar.current
        return healthVM.stepVM.weeklyWalkingDistance.first {
            cal.isDate($0.key, equalTo: Date(), toGranularity: .weekOfYear)
        }?.value ?? 0.0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("🚶‍♂️ Distance cette semaine")
                .font(.headline)

            HStack(spacing: 8) {
                Image(systemName: "figure.walk")
                    .foregroundColor(.blue)
                    .font(.title2)

                Text(String(format: "%.1f km", lastWeekKm))
                    .font(.title)
                    .bold()
            }

            Text("Marche, course et rando")
                .font(.caption)
                .foregroundColor(.secondary)

            // Affiche les clés disponibles pour debug
            if !healthVM.stepVM.weeklyWalkingDistance.isEmpty {
                Text("🧪 Clés :")
                    .font(.caption2)
                ForEach(healthVM.stepVM.weeklyWalkingDistance.keys.sorted(), id: \.self) { key in
                    Text("• \(key.formatted())")
                        .font(.caption2)
                }
            }
        }
        .padding()
        .onAppear {
            healthVM.stepVM.loadWalkingDistancePerWeek(range: .week)
        }
    }
}

#Preview {
    WalkingDistanceWidgetView()
        .environmentObject(sampleHealthVM)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .previewLayout(.sizeThatFits)
}

private let sampleHealthVM: HealthViewModel = {
    let vm = HealthViewModel()
    let cal = Calendar.current
    let today = cal.startOfDay(for: Date())
    let weekStart = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today))!
    vm.stepVM.weeklyWalkingDistance[weekStart] = 26.4
    return vm
}()
