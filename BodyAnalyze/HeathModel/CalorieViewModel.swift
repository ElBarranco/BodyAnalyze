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
    /// Calories actives par jour
    @Published var caloriesActivePerDay: [Date: Double] = [:]
    /// Calories basales par jour
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

// MARK: - NEAT Trend Analysis

/// Enum pour l'état du NEAT
enum NEATStatus {
    case moreActive
    case lessActive
    case stable
}

/// Modèle pour le statut NEAT
struct NEATTrend {
    let status: NEATStatus
    let variationPercentage: Double
    let averageLast2Days: Double
    let baseline28Days: Double
}

extension CalorieViewModel {
    /// Calcule la tendance NEAT (calories actives) sur 48h vs 28j
    var neatTrend: NEATTrend? {
        let calendar = Calendar.current
        let now = Date()
        let today = calendar.startOfDay(for: now)

        // Récupère les 28 derniers jours
        let last28Days = (1...28).compactMap { i -> Date? in
            guard let date = calendar.date(byAdding: .day, value: -i, to: today) else { return nil }
            return calendar.startOfDay(for: date)
        }

        // Moyenne 28 jours
        let baselineValues = last28Days.compactMap { caloriesActivePerDay[$0] }
        guard !baselineValues.isEmpty else { return nil }
        let baselineAverage = baselineValues.reduce(0, +) / Double(baselineValues.count)

        // ⚠️ Correction du jour en cours
        let secondsSinceStartOfToday = now.timeIntervalSince(today)
        let ratioTodayComplete = min(secondsSinceStartOfToday / (24 * 60 * 60), 1.0)
        let todayRaw = caloriesActivePerDay[today] ?? 0
        let todayEstimated = ratioTodayComplete > 0 ? todayRaw / ratioTodayComplete : 0

        // Hier
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today).map({ calendar.startOfDay(for: $0) }) else {
            return nil
        }
        let yesterdayValue = caloriesActivePerDay[yesterday] ?? 0

        // Moyenne ajustée sur les 2 derniers jours (hier + estimation today)
        let averageLast2 = (yesterdayValue + todayEstimated) / 2

        // Variation en %
        let variation = ((averageLast2 - baselineAverage) / baselineAverage) * 100

        // Statut
        let status: NEATStatus
        switch variation {
        case ..<(-15): status = .lessActive
        case 15...:    status = .moreActive
        default:       status = .stable
        }

        return NEATTrend(
            status: status,
            variationPercentage: variation,
            averageLast2Days: averageLast2,
            baseline28Days: baselineAverage
        )
    }
}
