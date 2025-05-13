import Foundation
import HealthKit

class GlycogenEstimationViewModel: ObservableObject {
    @Published var weight: Double = 70
    @Published var sex: String = "Homme"
    @Published var duration: Double = 1.5
    @Published var intensity: String = "Z2"
    @Published var altitude: Double = 0
    @Published var temperature: Double = 20
    @Published var glycogenLoad: GlycogenLoadLevel = .normal
    @Published var eatingDuring: Bool = false
    @Published var carbsPerHour: Double = 30
    @Published var result: GlycogenEstimationResult?
    @Published var activityType: ActivityType = .hike
    @Published var elevationGain: Double = 0 // 🔼 Ajout dénivelé

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
            elevationGain: elevationGain // ✅ Ajout ici aussi
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
    
    func thresholdCrossingTimes() -> (halfTime: Double?, criticalTime: Double?) {
        guard let result = result else { return (nil, nil) }

        let durationPerStep = duration / 100
        var halfTime: Double?
        var criticalTime: Double?

        for (i, value) in result.timeSeries.enumerated() {
            let percent = value / result.reserveMax
            if halfTime == nil && percent < 0.5 {
                halfTime = Double(i) * durationPerStep
            }
            if criticalTime == nil && percent < 0.3 {
                criticalTime = Double(i) * durationPerStep
                break
            }
        }

        return (halfTime, criticalTime)
    }
    
    
}

extension Double {
    func asHourMinuteString() -> String {
        let hours = Int(self)
        let minutes = Int((self - Double(hours)) * 60)
        return String(format: "%dh%02d", hours, minutes)
    }
}
