//
//  NEATTrendWidget.swift
//  BodyAnalyze
//
//  Created by Lionel Barranco on 18/05/2025.
//


import SwiftUI

struct NEATTrendWidget: View {
    @ObservedObject var viewModel: CalorieViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let trend = viewModel.neatTrend {
                HStack {
                    switch trend.status {
                    case .moreActive:
                        Text("🟢 Vous êtes plus actif que d’habitude !")
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                    case .lessActive:
                        Text("🔴 Vous êtes moins actif que d’habitude.")
                            .fontWeight(.semibold)
                            .foregroundColor(.red)
                    case .stable:
                        Text("🟡 Activité stable ces derniers jours.")
                            .fontWeight(.semibold)
                            .foregroundColor(.orange)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("📊 Moy. 48h : \(Int(trend.averageLast2Days)) kcal")
                    Text("📈 Moy. 28j : \(Int(trend.baseline28Days)) kcal")
                    Text("↕️ Variation : \(String(format: "%.1f", trend.variationPercentage))%")
                        .foregroundColor(trend.variationPercentage < 0 ? .red : .green)
                }
                .font(.caption)
            } else {
                Text("🔄 Chargement des données NEAT...")
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}