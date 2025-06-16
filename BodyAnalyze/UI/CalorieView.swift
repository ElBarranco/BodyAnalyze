//
//  CalorieView.swift
//  BodyAnalyze
//
//  Created by Lionel Barranco on 05/05/2025.
//

import SwiftUI

struct CalorieView: View {
    @EnvironmentObject var healthVM: HealthViewModel

    var body: some View {
        NavigationWrapperView(title: "Calories 🔥") {
            ScrollView {
                TileGrid {
                    
                    // 🔥 Widget NEAT : tendance de mouvement
                    Tile(span: .full) {
                        NEATTrendWidget(viewModel: healthVM.calorieVM)
                    }.wrapped()
                    
                    // 🔥 Histogramme calories actives vs basales
                    Tile(span: .full) {
                        VerticalCaloriesChartView(
                            activeCalories: healthVM.calorieVM.caloriesActivePerDay,
                            basalCalories: healthVM.calorieVM.caloriesBasalPerDay
                        )
                    }.wrapped()

                    // 🔥 Graphique calories totales
                    Tile(span: .full) {
                        CalorieGraphView(
                            calorieData: healthVM.calorieVM.totalCaloriesPerDay
                        )
                    }.wrapped()

                    // 📈 Courbe hebdo calories
                    Tile(span: .full) {
                        WeeklyCaloriesLineChartView(
                            activeCalories: healthVM.calorieVM.caloriesActivePerDay,
                            basalCalories: healthVM.calorieVM.caloriesBasalPerDay
                        )
                    }.wrapped()
                }
                .padding(.vertical)
            }
        }
    }
}
