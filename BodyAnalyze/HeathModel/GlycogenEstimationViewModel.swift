import Foundation
import HealthKit

class GlycogenEstimationViewModel: ObservableObject {
    @Published var weight: Double = 70
    @Published var sex: String = "Homme"
    @Published var duration: Double = 1.5
    @Published var intensity: String = "Z2"
    @Published var altitude: Double = 0
    @Published var temperature: Double = 20
    @Published var elevationGain: Double = 0
    @Published var distance: Double = 0 // ✅ NOUVEAU
    @Published var glycogenLoad: GlycogenLoadLevel = .normal
    @Published var eatingDuring: Bool = false
    @Published var carbsPerHour: Double = 30
    @Published var activityType: ActivityType = .hike
    @Published var result: GlycogenEstimationResult?

    private let healthManager = HealthManager()

    func estimate() {
        let estimation = GlycogenEstimator.estimateGlycogenUsage(
            weight: weight,
            sex: sex,
            duration: duration,
            intensity: intensity,
            altitude: altitude,
            temperature: temperature,
            glycogenLoad: glycogenLoad,
            activityType: activityType,
            eatingDuring: eatingDuring,
            carbsPerHour: carbsPerHour,
            elevationGain: elevationGain,
            distance: distance > 0 ? distance : nil
        )
        self.result = estimation
    }

    func loadHealthDataIfNeeded() {
        healthManager.requestAuthorization { [weak self] success, _ in
            guard let self = self, success else { return }
            self.healthManager.loadUserCharacteristics { sex, age, weight in
                DispatchQueue.main.async {
                    if let s = sex { self.sex = s }
                    if let w = weight { self.weight = w }
                }
            }
        }
    }

    func thresholdCrossingTimes() -> (Double?, Double?) {
        guard let result else { return (nil, nil) }
        let values = result.timeSeries
        let step = duration / Double(values.count)

        var time50: Double?
        var time30: Double?

        for (i, v) in values.enumerated() {
            let pct = v / result.reserveMax
            let t = Double(i) * step
            if time50 == nil && pct < 0.5 {
                time50 = t
            }
            if time30 == nil && pct < 0.3 {
                time30 = t
                break
            }
        }
        return (time50, time30)
    }
}
