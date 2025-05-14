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
        elevationGain: Double,
        distance: Double? = nil
    ) -> GlycogenEstimationResult {

        // 🧠 Sexe : modifie la réserve totale (moins de muscle = moins de glycogène)
        let sexModifier = (sex.lowercased() == "femme") ? 0.85 : 1.0
        let reserveMax = weight * 15.0 * glycogenLoad.percentageOfMax * sexModifier

        // ⚡️ Dépense énergétique par heure
        let kcalPerHour = EnergyExpenditureModel.kcalPerKgPerHour(for: activityType, intensity: intensity) * weight

        // 🔁 Coefficients contextuels
        var altitudeCoeff = 1.0
        if altitude > 2500 {
            altitudeCoeff += ((altitude - 2500) / 2500) * 0.15
        }

        var tempCoeff = 1.0
        if temperature < 5 {
            tempCoeff += (5 - temperature) * 0.02
        }

        let elevationCoeff = 1.0 + min(elevationGain / 1000.0 * 0.15, 0.3)

        var distanceCoeff = 1.0
        if let km = distance, km > 20 {
            distanceCoeff += (km - 20) * 0.015
        }

        // 🔥 Coût énergétique réel des glucides (par heure)
        let zoneGlucoseCoeff: [String: Double] = [
            "Z1": 0.4,
            "Z2": 0.55,
            "Z3": 0.7,
            "Z4": 0.85,
            "Z5": 0.95
        ]
        let glucoseRatio = zoneGlucoseCoeff[intensity] ?? 0.55
        let totalCoeff = glucoseRatio * altitudeCoeff * tempCoeff * elevationCoeff * distanceCoeff

        // 📉 Simulation en 100 pas de temps
        let dt = duration / 100.0
        var current = reserveMax
        var values: [Double] = []

        for i in 0..<100 {
            let t = dt * Double(i)

            // 🍽️ Repas placé au milieu de l'activité (durée/2)
            if eatingDuring && abs(t - duration / 2) < 0.25 {
                // Simule un apport progressif de 600 kcal (~90g glucides)
                current += (600 * 0.6 / 4) / 10.0
            }

            // 🍌 Collation toutes les 2h si activé
            if eatingDuring && (t > 0) && (Int(t * 60) % 120 == 0) {
                current += (150 * 0.6) / 4
            }

            let kcal = kcalPerHour * dt
            let used = kcal * totalCoeff / 4.0
            let ingest = eatingDuring ? carbsPerHour * dt * 0.6 : 0.0

            current -= used
            current += ingest
            current = max(0, current)
            values.append(current)
        }

        let remaining = values.last ?? 0
        let percent = (remaining / reserveMax) * 100.0

        return GlycogenEstimationResult(
            reserveMax: reserveMax,
            glycogenUsed: reserveMax - remaining,
            remaining: remaining,
            percentageRemaining: percent,
            timeSeries: values
        )
    }
}
