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
        carbsPerHour: Double,
        elevationGain: Double
    ) -> GlycogenEstimationResult {
        
        // 💾 Réserve glycogène max
        let reserveMax = weight * 15.0 * glycogenLoad.percentageOfMax
        let coeff = activityType.baseCoeff

        // 🏔️ Coeff altitude
        var altitudeCoeff = 1.0
        if altitude > 2500 {
            altitudeCoeff += ((altitude - 2500) / 2500) * 0.15
        }

        // ❄️ Coeff température
        var tempCoeff = 1.0
        if temperature < 5 {
            tempCoeff += (5 - temperature) * 0.02
        }

        // 🔼 Coeff dénivelé (max +30%)
        let elevationCoeff = 1.0 + min(elevationGain / 1000.0 * 0.15, 0.3)

        // 🔁 Simulation sur 100 pas de temps
        let kcalPerHour = weight * 8.5
        let dt = duration / 100
        var current = reserveMax
        var values: [Double] = []

        for i in 0..<100 {
            let t = dt * Double(i)

            // 🍽️ Repas progressif entre 4h–5h
            if 4.0...5.0 ~= t {
                current += (600 * 0.6 / 4) / 10.0
            }

            // 🍌 Collation toutes les 2h si activé
            if Int(t) % 2 == 0 && i % 10 == 0 && eatingDuring {
                current += (150 * 0.6) / 4
            }

            // 🔥 Dépense nette
            let kcal = kcalPerHour * dt
            let used = kcal * coeff * altitudeCoeff * tempCoeff * elevationCoeff / 4
            let ingest = eatingDuring ? carbsPerHour * dt * 0.6 : 0

            current -= used
            current += ingest
            current = max(0, current)
            values.append(current)
        }

        // 📊 Résultat final
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
