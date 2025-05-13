import Foundation
import HealthKit

struct CourseMetrics {
    let date: Date
    let duration: TimeInterval
    let distance: Double
    let averageBPM: Double
    let averageCadence: Double
}

class CourseManager {
    private let healthStore: HKHealthStore

    init(healthStore: HKHealthStore = HKHealthStore()) {
        self.healthStore = healthStore
    }

    // 🏃‍♂️ Récupère les workouts de type course à pied
    func fetchRunningWorkouts(from startDate: Date, to endDate: Date, completion: @escaping ([HKWorkout]) -> Void) {
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        let query = HKSampleQuery(sampleType: .workoutType(), predicate: predicate, limit: 50, sortDescriptors: [sort]) { _, samples, _ in
            let workouts = (samples as? [HKWorkout])?.filter {
                $0.workoutActivityType == .running
            } ?? []
            completion(workouts)
        }

        healthStore.execute(query)
    }
    
    func getWeeklyRunningDistance(completion: @escaping (Double) -> Void) {
        let calendar = Calendar.current
        let now = Date()
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!

        fetchRunningWorkouts(from: startOfWeek, to: now) { workouts in
            let totalDistance = workouts.reduce(0.0) { partialResult, workout in
                partialResult + (workout.totalDistance?.doubleValue(for: .meterUnit(with: .kilo)) ?? 0)
            }
            completion(totalDistance)
        }
    }

    
    func getGroundContactTimeAverage(for workout: HKWorkout, completion: @escaping (Double?) -> Void) {
        guard let gctType = HKQuantityType.quantityType(forIdentifier: .runningGroundContactTime) else {
            completion(nil)
            return
        }

        let predicate = HKQuery.predicateForSamples(withStart: workout.startDate, end: workout.endDate, options: .strictStartDate)

        let query = HKSampleQuery(sampleType: gctType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, _ in
            guard let quantitySamples = samples as? [HKQuantitySample], !quantitySamples.isEmpty else {
                completion(nil)
                return
            }

            let total = quantitySamples.reduce(0.0) { $0 + $1.quantity.doubleValue(for: .secondUnit(with: .milli)) }
            let average = total / Double(quantitySamples.count)

            completion(average)
        }

        healthStore.execute(query)
    }
    
    func getAverageStrideLength(for workout: HKWorkout, completion: @escaping (Double?) -> Void) {
        guard let strideType = HKQuantityType.quantityType(forIdentifier: .runningStrideLength) else {
            completion(nil)
            return
        }

        let predicate = HKQuery.predicateForSamples(withStart: workout.startDate, end: workout.endDate, options: .strictStartDate)

        let query = HKSampleQuery(sampleType: strideType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, _ in
            guard let strideSamples = samples as? [HKQuantitySample], !strideSamples.isEmpty else {
                completion(nil)
                return
            }

            let totalStride = strideSamples.reduce(0.0) {
                $0 + $1.quantity.doubleValue(for: .meter())
            }

            let average = totalStride / Double(strideSamples.count)
            completion(average)
        }

        healthStore.execute(query)
    }
    
    func getLastRunningWorkout(completion: @escaping (HKWorkout?) -> Void) {
        let now = Date()
        let start = Calendar.current.date(byAdding: .month, value: -1, to: now)!

        fetchRunningWorkouts(from: start, to: now) { workouts in
            completion(workouts.first)
        }
    }
    // 🔍 Retourne la dernière session + données mock (pour l’instant)
    func getLastRunningMetrics(completion: @escaping (CourseMetrics?) -> Void) {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .month, value: -1, to: endDate)!

        fetchRunningWorkouts(from: startDate, to: endDate) { workouts in
            guard let last = workouts.first else {
                completion(nil)
                return
            }

            // TODO: remplacer par un vrai calcul de cadence + BPM
            let metrics = CourseMetrics(
                date: last.startDate,
                duration: last.duration,
                distance: last.totalDistance?.doubleValue(for: .meterUnit(with: .kilo)) ?? 0,
                averageBPM: 148, // mock
                averageCadence: 164 // mock
            )
            completion(metrics)
        }
    }
}
