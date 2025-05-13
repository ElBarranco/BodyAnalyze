//
//  TrainingView.swift
//  BodyAnalyze
//
//  Created by Lionel Barranco on 05/05/2025.
//

import SwiftUI

struct TrainingView: View {
    @EnvironmentObject var healthVM: HealthViewModel
    @State private var showGlycogenEstimator = false

    var body: some View {
        NavigationWrapperView(title: "Entraînement 🏋️") {
            ScrollView {
                TileGrid {
                    // 💨 EPOC
                    Tile(span: .full) {
                        EpocChartView()
                    }.wrapped()

                    // 🔄 Training Load Arc
                    Tile(span: .half) {
                        TrainingLoadArcView(epoc: healthVM.trainingVM.getWeeklyEPOCTotal())
                    }.wrapped()

                    // 🆕 Moyenne EPOC hebdo
                    Tile(span: .half) {
                        EPOCAverageWidgetView(
                            averageEPOC: healthVM.trainingVM.getAverageEPOCOverLastWeeks()
                        )
                    }.wrapped()

                    // 📈 Forme vs Fatigue (simulation)
                    Tile(span: .full) {
                        FormeFatigueWidgetView(isSimulated: true)
                    }.wrapped()

                    // 📅 Analyse repos mensuelle
                    Tile(span: .full) {
                        MonthlyRestAnalysisView()
                    }.wrapped()

                    // 🆕 Graph Trimp
                    Tile(span: .full) {
                        TrimpChartView()
                    }.wrapped()

                    // ⚡️ Estimation Glycogène
                    Tile(span: .full) {
                        Button(action: {
                            showGlycogenEstimator = true
                        }) {
                            HStack {
                                Image(systemName: "bolt.fill")
                                    .foregroundColor(.orange)
                                Text("Estimer ma dépense de glycogène")
                                    .fontWeight(.semibold)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(12)
                        }
                    }.wrapped()
                }
                .padding(.vertical)
            }
        }
        // 🧪 Sheet affichée au clic
        .sheet(isPresented: $showGlycogenEstimator) {
            NavigationView {
                GlycogenEstimatorView()
            }
        }
    }
}
