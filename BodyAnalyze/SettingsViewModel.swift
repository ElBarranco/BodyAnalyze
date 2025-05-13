// SettingsViewModel.swift
import HealthKit

struct SettingsViewModel {
    private static let healthStore = HKHealthStore()

    /// Récupère l’âge via HealthKit et renvoie 220 - âge
    static func computeDefaultMaxBPM(completion: @escaping (Double) -> Void) {
        guard let dobType = HKObjectType.characteristicType(forIdentifier: .dateOfBirth) else {
            completion(190) // valeur de secours
            return
        }
        healthStore.requestAuthorization(toShare: [], read: [dobType]) { success, _ in
            guard success,
                  let comps = try? healthStore.dateOfBirthComponents(),
                  let year = comps.year
            else {
                completion(190)
                return
            }
            let age = Calendar.current.component(.year, from: Date()) - year
            let defaultMax = max(100, min(220, 220 - age))
            completion(Double(defaultMax))
        }
    }
}
