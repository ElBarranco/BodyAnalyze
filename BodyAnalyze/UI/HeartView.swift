//
//  HeartView.swift
//  BodyAnalyze
//
//  Created by Lionel Barranco on 05/05/2025.
//

import SwiftUI

struct HeartView: View {
    @EnvironmentObject var healthVM: HealthViewModel

    var body: some View {
        NavigationWrapperView(title: "Analyse Cœur ❤️") {
            ScrollView {
                TileGrid {
                    // 📊 Titre + HRV
                    Tile(span: .full) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("📊 Variabilité de la FC (HRV)")
                                .font(.headline)
                            HRVChartView(vm: healthVM.heartVM)
                                .frame(height: 350)
                        }
                    }.wrapped()

                    // 🔻 Zones de fréquence cardiaque
                    Tile(span: .full) {
                        CardioZoneView()
                    }.wrapped()

                    // 📈 VFC Max
                    Tile(span: .full) {
                        VFCMaxChartView()
                    }.wrapped()
                    
                    // 🫀 Moyenne FC au repos (widget résumé)
                      Tile(span: .half) {
                          RestingHRWidgetView(
                              weeklyAverage: healthVM.heartVM.restingHRAnalyzer.averageLast7Days,
                              referenceAverage: healthVM.heartVM.restingHRAnalyzer.averageReference
                          )
                      }.wrapped()
                    
                    // 🫀 Tendance FC repos (48h vs 7j)
                    Tile(span: .half) {
                        RestingHRTrendWidgetView(
                            average48h: healthVM.heartVM.averageRestingHR(last: 2),
                            average7d: healthVM.heartVM.averageRestingHR(last: 7)
                        )
                    }.wrapped()
                    
                    // 🫀 FC au repos
                    Tile(span: .full) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("🫀 Fréquence cardiaque au repos")
                                .font(.headline)

                            RestingHeartRateChartView(analyzer: healthVM.heartVM.restingHRAnalyzer)
                                .frame(height: 300)
                        }
                    }.wrapped()
                }
                .padding(.vertical)
            }
        }
    }
}
