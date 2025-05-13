// StepCountViewModel.swift
// BodyAnalyze
// Created by Lionel Barranco on 12/05/2025.

import Foundation
import HealthKit

/// ViewModel dédié à l'analyse du nombre de pas (quotidien et running)
class StepCountViewModel: ObservableObject {
    // MARK: - Published properties
    @Published var stepsPerDay: [Date: Int] = [:]
    @Published var stepStreak: Int = 0
    @Published var runningStepsPerDay: [Date: Int] = [:]
    @Published var averageSteps: Double = 0.0
    @Published var averageRunningSteps: Double = 0.0
    @Published var weeklyWalkingDistance: [Date: Double] = [:] // 🚶‍♂️ Distance par semaine (en km)

    @Published var dailyStepGoal: Int? {
        didSet {
            if let goal = dailyStepGoal {
                UserDefaults.standard.set(goal, forKey: "dailyStepGoal")
            } else {
                UserDefaults.standard.removeObject(forKey: "dailyStepGoal")
            }
        }
    }

    // ✅ Indique si un objectif est défini
    var hasDefinedGoal: Bool {
        (dailyStepGoal ?? 0) > 0
    }

    // MARK: - Accès rapide aux pas du jour
    var todaySteps: Int {
        let today = Calendar.current.startOfDay(for: Date())
        return stepsPerDay[today] ?? 0
    }

    private let healthManager = HealthManager()

    // MARK: - Init
    init() {
        if let saved = UserDefaults.standard.object(forKey: "dailyStepGoal") as? Int {
            dailyStepGoal = saved
        }
    }

    // MARK: - Data Loading

    func loadStepsData(range: TimeRange) {
        healthManager.requestAuthorization { [weak self] success, _ in
            guard let self = self, success else { return }
            self.healthManager.fetchStepCountPerDay(for: range) { map in
                DispatchQueue.main.async {
                    self.stepsPerDay = map
                    self.computeAverage(from: map, assignTo: &self.averageSteps)
                    self.computeStepStreak()
                }
            }
        }
    }

    func loadRunningStepsData(range: TimeRange) {
        healthManager.requestAuthorization { [weak self] success, _ in
            guard let self = self, success else { return }
            self.healthManager.fetchRunningStepCountPerDay(for: range) { map in
                DispatchQueue.main.async {
                    self.runningStepsPerDay = map
                    self.computeAverage(from: map, assignTo: &self.averageRunningSteps)
                }
            }
        }
    }

    /// 🚶‍♂️ Charge la distance hebdomadaire (walking + running)
    func loadWalkingDistancePerWeek(range: TimeRange) {
        healthManager.requestAuthorization { [weak self] success, _ in
            guard let self = self, success else { return }
            self.healthManager.fetchWalkingRunningDistancePerWeek(range: range) { map in
                DispatchQueue.main.async {
                    self.weeklyWalkingDistance = map
                }
            }
        }
    }
    
    func debugDistanceLog() {
        healthManager.requestAuthorization { [weak self] success, _ in
            guard let self = self, success else {
                print("❌ Autorisation refusée")
                return
            }
            self.healthManager.fetchWalkingRunningDistancePerWeek(range: .month) { map in
                print("✅ Données reçues :", map)
            }
        }
    }

    func computeStepStreak() {
        let goal = dailyStepGoal ?? 0
        let today = Calendar.current.startOfDay(for: Date())

        var currentDate = today
        if (stepsPerDay[today] ?? 0) < goal {
            currentDate = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        }

        var streak = 0

        while true {
            let steps = stepsPerDay[currentDate] ?? 0
            if steps >= goal {
                streak += 1
                currentDate = Calendar.current.date(byAdding: .day, value: -1, to: currentDate)!
            } else {
                break
            }
        }

        DispatchQueue.main.async {
            self.stepStreak = streak
        }
    }

    // MARK: - Helpers

    private func computeAverage(from map: [Date: Int], assignTo value: inout Double) {
        guard !map.isEmpty else {
            value = 0
            return
        }
        let total = map.values.reduce(0, +)
        value = Double(total) / Double(map.count)
    }
}
