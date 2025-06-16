import Foundation
import HealthKit

/// ViewModel dédié aux métriques cardiaques (FC, HRV, zones, VFC, Body Battery, objectifs)
class HeartMetricsViewModel: ObservableObject {
    // MARK: - Published properties
    @Published var maxHeartRate: Double = 190.0
    @Published var restingHR: Double = 60.0
    @Published var hrvValue: Double = 55.0
    @Published var hrvSamples: [HRVSample] = []
    @Published var lastHRVDate: Date?
    @Published var vfcMaxPerDay: [Date: Double] = [:]
    @Published var vfcMinPerDay: [Date: Double] = [:]
    @Published var zoneDurations: [Int: TimeInterval] = [:]
    @Published var bodyBatteryScore: Double = 5.0 {
        didSet {
            let defaults = UserDefaults(suiteName: "group.Octopy.BodyAnalyze")
            defaults?.set(bodyBatteryScore, forKey: "bodyBatteryScore")
        }
    }
    @Published var showGoalEditor: Bool = false
    @Published var cardioGoals: [Int: Double] = [
        2: 50.0,
        3: 30.0,
        4: 20.0,
        5:  0.0
    ]
    
    // 🫀 Fréquence cardiaque au repos (historique)
    @Published var restingHREntries: [RestingHeartRateEntry] = []
    let restingHRAnalyzer = RestingHeartRateAnalyzer()

    // MARK: - Private
    private let healthManager = HealthManager()

    // MARK: - Init
    init() {
        // Restore Body Battery
        if let saved = UserDefaults(suiteName: "group.Octopy.BodyAnalyze")?
            .double(forKey: "bodyBatteryScore"), saved != 0 {
            bodyBatteryScore = saved
        }

        // Charger Max HR stocké ou par défaut
        let storedMax = UserDefaults.standard.double(forKey: "maxBPM")
        if storedMax > 0 {
            maxHeartRate = storedMax
        } else {
            SettingsViewModel.computeDefaultMaxBPM { mb in
                DispatchQueue.main.async {
                    self.maxHeartRate = mb
                    UserDefaults.standard.set(mb, forKey: "maxBPM")
                }
            }
        }
    }

    /// Charge toutes les données cardiaques pour la plage donnée
    func loadHeartData(range: TimeRange) {
        healthManager.requestAuthorization { success, error in
            guard success else {
                print("🔴 HealthKit auth failed:", error?.localizedDescription ?? "unknown")
                return
            }

            self.healthManager.fetchHRVSamples(for: range) { samples in
                DispatchQueue.main.async {
                    self.hrvSamples = samples.sorted { $0.date < $1.date }
                }
            }

            self.healthManager.fetchRestingHeartRate { hr in
                DispatchQueue.main.async {
                    if let hr = hr { self.restingHR = hr }
                }
            }

            self.healthManager.analyzeVFCMinMaxPerDay(for: range) { maxMap, minMap in
                DispatchQueue.main.async {
                    self.vfcMaxPerDay = maxMap
                    self.vfcMinPerDay = minMap
                }
            }

            self.healthManager.fetchRestingHeartRateHistory(for: range) { entries in
                DispatchQueue.main.async {
                    self.restingHREntries = entries
                    self.restingHRAnalyzer.entries = entries
                }
            }

            let start = range.startDate
            let end   = range.endDate
            self.healthManager.fetchWorkouts(from: start, to: end) { workouts in
                self.healthManager.analyzeHeartRateZones(
                    for: workouts,
                    maxHR: self.maxHeartRate,
                    restHR: self.restingHR
                ) { zones in
                    DispatchQueue.main.async {
                        self.zoneDurations = zones
                    }
                }

                DispatchQueue.main.async {
                    self.bodyBatteryScore = self.estimateBodyBatteryScore()
                }
            }
        }
    }

    // MARK: - Helpers

    private func estimateBodyBatteryScore() -> Double {
        Double.random(in: 4.0...8.5)
    }

    func hrvScore(sdnn: Double) -> Double {
        let healthyThreshold = 100.0
        let unhealthyThreshold = 10.0
        let raw = (sdnn - unhealthyThreshold)
                / (healthyThreshold - unhealthyThreshold)
                * 10.0
        return max(0, raw)
    }

    /// Moyenne de FC repos sur une période récente (ex: 2 jours ou 7 jours)
    func averageRestingHR(last days: Int) -> Double {
        let now = Date()
        let fromDate = Calendar.current.date(byAdding: .day, value: -days, to: now)!
        let recentEntries = restingHREntries.filter { $0.date >= fromDate }
        let values = recentEntries.map { Double($0.bpm) }
        guard !values.isEmpty else { return 0 }
        return values.reduce(0, +) / Double(values.count)
    }

    /// Différence entre les moyennes 48h et 7 jours (utile pour widget)
    var restingHRTrendDelta: Double {
        let avg48h = averageRestingHR(last: 2)
        let avg7d = averageRestingHR(last: 7)
        return avg48h - avg7d
    }
}
