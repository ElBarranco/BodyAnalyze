//
//  GlycogenEstimationResult.swift
//  BodyAnalyze
//
//  Created by Lionel Barranco on 08/05/2025.
//


import Foundation

/// Structure de résultat pour affichage
struct GlycogenEstimationResult {
    let reserveMax: Double
    let glycogenUsed: Double
    let remaining: Double
    let percentageRemaining: Double
}

enum GlycogenEstimator {
    static func estimateGlycogenUsage(
        weight: Double,
        sex: String,
        duration: Double,
        intensity: String,
        altitude: Double,
        temperature: Double,
        preLoaded: Bool,
        eatingDuring: Bool,
        carbsPerHour: Double
    ) -> GlycogenEstimationResult {

        let reserveMax = preLoaded ? weight * 15.0 : weight * 10.0

        let zoneCoeff: [String: Double] = [
            "Z1": 0.2,
            "Z2": 0.35,
            "Z3": 0.55,
            "Z4": 0.75,
            "Z5": 0.9
        ]
        let coeff = zoneCoeff[intensity] ?? 0.35

        var altitudeCoeff = 1.0
        if altitude > 2500 {
            altitudeCoeff += ((altitude - 2500) / 2500) * 0.15
        }

        var tempCoeff = 1.0
        if temperature < 5 {
            tempCoeff += (5 - temperature) * 0.02
        }

        let kcalPerHour = weight * 8.5
        let totalKcal = kcalPerHour * duration
        let kcalFromGlyco = totalKcal * coeff * altitudeCoeff * tempCoeff
        var gramsUsed = kcalFromGlyco / 4.0

        if eatingDuring {
            gramsUsed -= carbsPerHour * duration * 0.6
        }

        gramsUsed = max(0, gramsUsed)
        let remaining = max(0, reserveMax - gramsUsed)
        let percent = (remaining / reserveMax) * 100.0

        return GlycogenEstimationResult(
            reserveMax: reserveMax,
            glycogenUsed: gramsUsed,
            remaining: remaining,
            percentageRemaining: percent
        )
    }
}