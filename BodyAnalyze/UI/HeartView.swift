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
                }
                .padding(.vertical)
            }
        }
    }
}
