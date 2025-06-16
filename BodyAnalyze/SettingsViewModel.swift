import HealthKit
import Combine

class SettingsViewModel: ObservableObject {
    static let healthStore = HKHealthStore()

    @Published var age: Int?
    @Published var height: Double?  // en cm
    @Published var weight: Double?  // en kg

    init() {
        Self.requestAuthorization()
        fetchAllHealthData()
    }

    // ⚙️ Reprend ta méthode existante
    static func computeDefaultMaxBPM(completion: @escaping (Double) -> Void) {
        guard let dobType = HKObjectType.characteristicType(forIdentifier: .dateOfBirth) else {
            completion(190)
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

    // 🔐 Autorisation globale pour tout le reste
    static func requestAuthorization() {
        let typesToRead: Set = [
            HKObjectType.characteristicType(forIdentifier: .dateOfBirth)!,
            HKObjectType.quantityType(forIdentifier: .height)!,
            HKObjectType.quantityType(forIdentifier: .bodyMass)!
        ]

        healthStore.requestAuthorization(toShare: [], read: typesToRead) { _, _ in }
    }

    // 🔄 Lecture des données HealthKit
    func fetchAllHealthData() {
        fetchAge()
        fetchHeight()
        fetchWeight()
    }

    private func fetchAge() {
        if let birthDate = try? Self.healthStore.dateOfBirthComponents().date {
            let now = Date()
            let ageComponents = Calendar.current.dateComponents([.year], from: birthDate, to: now)
            DispatchQueue.main.async {
                self.age = ageComponents.year
            }
        }
    }

    private func fetchHeight() {
        guard let heightType = HKSampleType.quantityType(forIdentifier: .height) else { return }

        let query = HKSampleQuery(sampleType: heightType, predicate: nil, limit: 1, sortDescriptors: [.init(key: HKSampleSortIdentifierEndDate, ascending: false)]) { _, results, _ in
            if let sample = results?.first as? HKQuantitySample {
                let heightInCm = sample.quantity.doubleValue(for: .meterUnit(with: .centi))
                DispatchQueue.main.async {
                    self.height = heightInCm
                }
            }
        }
        Self.healthStore.execute(query)
    }

    private func fetchWeight() {
        guard let weightType = HKSampleType.quantityType(forIdentifier: .bodyMass) else { return }

        let query = HKSampleQuery(sampleType: weightType, predicate: nil, limit: 1, sortDescriptors: [.init(key: HKSampleSortIdentifierEndDate, ascending: false)]) { _, results, _ in
            if let sample = results?.first as? HKQuantitySample {
                let weightInKg = sample.quantity.doubleValue(for: .gramUnit(with: .kilo))
                DispatchQueue.main.async {
                    self.weight = weightInKg
                }
            }
        }
        Self.healthStore.execute(query)
    }
}
