//
//  GlycogenEstimationViewModel.swift
//  BodyAnalyze
//
//  Created by Lionel Barranco on 08/05/2025.
//


import Foundation
import HealthKit

/// ViewModel dédié à l’estimation de la dépense glycogénique
class GlycogenEstimationViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var weight: Double = 70
    @Published var sex: String = "Homme"
    @Published var age: Int = 30
    @Published var duration: Double = 1.5
    @Published var intensity: String = "Z2"
    @Published var altitude: Double = 0
    @Published var temperature: Double = 20
    @Published var preLoaded: Bool = true
    @Published var eatingDuring: Bool = false
    @Published var carbsPerHour: Double = 30

    @Published var result: GlycogenEstimationResult?

    private let healthManager = HealthManager()

    // MARK: - Public API

    func estimate() {
        let estimation = GlycogenEstimator.estimateGlycogenUsage(
            weight: weight,
            sex: sex,
            duration: duration,
            intensity: intensity,
            altitude: altitude,
            temperature: temperature,
            preLoaded: preLoaded,
            eatingDuring: eatingDuring,
            carbsPerHour: carbsPerHour
        )
        self.result = estimation
    }

    func loadHealthDataIfNeeded() {
        healthManager.requestAuthorization { [weak self] success, _ in
            guard let self = self, success else { return }
            self.healthManager.loadUserCharacteristics { sex, age, weight in
                DispatchQueue.main.async {
                    if let s = sex { self.sex = s }
                    if let a = age { self.age = a }
                    if let w = weight { self.weight = w }
                }
            }
        }
    }
}