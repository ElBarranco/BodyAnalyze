//
//  CalorieViewModel.swift
//  BodyAnalyze
//
//  Created by Lionel Barranco on 30/04/2025.
//


import Foundation
import HealthKit

/// ViewModel dédié aux données caloriques (actives, basales, totales)
class CalorieViewModel: ObservableObject {
    // MARK: - Published properties
    /// Calories actives par jour\    
    @Published var caloriesActivePerDay: [Date: Double] = [:]
    /// Calories basales par jour\    
    @Published var caloriesBasalPerDay: [Date: Double] = [:]

    // MARK: - Computed properties
    /// Total calories (active + basal) par jour
    var totalCaloriesPerDay: [Date: Double] {
        var result: [Date: Double] = [:]
        let calendar = Calendar.current
        for (date, active) in caloriesActivePerDay {
            let day = calendar.startOfDay(for: date)
            let basal = caloriesBasalPerDay[day] ?? 0
            result[day] = active + basal
        }
        return result
    }

    // MARK: - Private
    private let healthManager = HealthManager()

    // MARK: - Data Loading

    /// Charge la répartition caloriques pour la plage donnée
    /// - Parameter range: plage temporelle (semaine ou mois)
    func loadCaloriesData(range: TimeRange) {
        healthManager.requestAuthorization { success, error in
            guard success else {
                print("🔴 HealthKit auth failed:", error?.localizedDescription ?? "unknown")
                return
            }

            // Fetch breakdown active vs basal
            self.healthManager.fetchCaloriesBreakdownPerDay(for: range) { activeMap, basalMap in
                DispatchQueue.main.async {
                    self.caloriesActivePerDay = activeMap
                    self.caloriesBasalPerDay  = basalMap
                }
            }
        }
    }
}
