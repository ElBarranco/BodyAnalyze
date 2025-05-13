import Foundation

enum GlycogenEstimator {
    static func estimateGlycogenUsage(
        weight: Double,
        sex: String,
        duration: Double,
        intensity: String,
        altitude: Double,
        temperature: Double,
        glycogenLoad: GlycogenLoadLevel,
        activityType: ActivityType,
        eatingDuring: Bool,
        carbsPerHour: Double
    ) -> GlycogenEstimationResult {
        
        let reserveMax = weight * 15.0 * glycogenLoad.percentageOfMax
        let coeff = activityType.baseCoeff

        var altitudeCoeff = 1.0
        if altitude > 2500 {
            altitudeCoeff += ((altitude - 2500) / 2500) * 0.15
        }

        var tempCoeff = 1.0
        if temperature < 5 {
            tempCoeff += (5 - temperature) * 0.02
        }

        let kcalPerHour = weight * 8.5
        let dt = duration / 100
        var current = reserveMax
        var values: [Double] = []

        for i in 0..<100 {
            let t = dt * Double(i)

            // Repas entre 4–5h
            if 4.0...5.0 ~= t {
                current += (600 * 0.6 / 4) / 10.0
            }

            // Collation toutes les 2h si activé
            if Int(t) % 2 == 0 && i % 10 == 0 && eatingDuring {
                current += (150 * 0.6) / 4
            }

            let kcal = kcalPerHour * dt
            let used = kcal * coeff * altitudeCoeff * tempCoeff / 4
            let ingest = eatingDuring ? carbsPerHour * dt * 0.6 : 0

            current -= used
            current += ingest
            current = max(0, current)
            values.append(current)
        }

        let remaining = values.last ?? 0
        let percent = remaining / reserveMax * 100

        return GlycogenEstimationResult(
            reserveMax: reserveMax,
            glycogenUsed: reserveMax - remaining,
            remaining: remaining,
            percentageRemaining: percent,
            timeSeries: values
        )
    }
}
