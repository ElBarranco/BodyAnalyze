import Foundation
import HealthKit

class TrainingViewModel: ObservableObject {
    @Published var workoutCount: Int = 0
    @Published var epocPerDay: [Date: Double] = [:]
    @Published var trimpPerDay: [Date: Double] = [:]
    @Published var trainingTypesByDay: [Date: TrainingType] = [:]
    @Published var disciplineByDay: [Date: WorkoutDiscipline] = [:] // ✅ Nouveau

    @Published var trainingLoad7d: Double = 0.0
    @Published var maxHeartRate: Double = 190.0
    @Published var restingHR: Double = 60.0
    @Published var isMale: Bool = true
    @Published var currentWeekStart: Date = Calendar.current.startOfWeek(for: Date())

    private let healthManager = HealthManager()
    private var authorized = false

    func loadRecentWeeksData(weeks: Int = 6) {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        self.currentWeekStart = cal.startOfWeek(for: today)

        guard let start = cal.date(byAdding: .day, value: -7 * weeks, to: today) else { return }
        loadTrainingData(from: start, to: today)
    }

    func loadTrainingData(from start: Date, to end: Date) {
        if !authorized {
            healthManager.requestAuthorization { success, error in
                guard success else {
                    print("🔴 HealthKit auth failed:", error?.localizedDescription ?? "unknown")
                    return
                }
                DispatchQueue.main.async { self.authorized = true }
                self.fetchTrainingData(from: start, to: end)
            }
        } else {
            fetchTrainingData(from: start, to: end)
        }
    }

    private func fetchTrainingData(from start: Date, to end: Date) {
        healthManager.fetchWorkouts(from: start, to: end) { workouts in
            DispatchQueue.main.async {
                self.workoutCount = workouts.count
                print("📥 \(workouts.count) entraînements récupérés de \(start.formatted()) à \(end.formatted())")
            }

            self.analyzeTrainingDays(from: workouts)
            self.detectDisciplines(from: workouts) // ✅ Détection des disciplines

            self.healthManager.analyzeEPOCPerDayV2(
                for: workouts,
                maxHeartRate: self.maxHeartRate
            ) { map in
                DispatchQueue.main.async {
                    self.epocPerDay = map
                    self.updateLoad7d()
                }
            }

            self.healthManager.analyzeTRIMPPerWorkout(
                for: workouts,
                restingHR: self.restingHR,
                maxHR: self.maxHeartRate,
                isMale: self.isMale
            ) { map in
                DispatchQueue.main.async {
                    self.trimpPerDay = map
                    self.updateLoad7d()
                }
            }
        }
    }

    private func detectDisciplines(from workouts: [HKWorkout]) {
        let cal = Calendar.current
        var map: [Date: WorkoutDiscipline] = [:]

        for workout in workouts {
            let day = cal.startOfDay(for: workout.startDate)

            let discipline: WorkoutDiscipline
            switch workout.workoutActivityType {
            case .running:     discipline = .running
            case .hiking:      discipline = .hiking
            case .traditionalStrengthTraining, .functionalStrengthTraining:
                discipline = .strength
            case .cycling:     discipline = .cycling
            case .swimming:    discipline = .swimming
            default:           discipline = .unknown
            }

            map[day] = discipline
        }

        DispatchQueue.main.async {
            self.disciplineByDay = map
        }
    }

    private func analyzeTrainingDays(from workouts: [HKWorkout]) {
        var map: [Date: TrainingType] = [:]
        var durations: [Date: Double] = [:]
        let cal = Calendar.current

        for w in workouts {
            let day = cal.startOfDay(for: w.startDate)
            durations[day, default: 0] += w.duration / 60
        }

        for (day, mins) in durations {
            map[day] = mins > 30 ? .heavy : .light
        }

        if let last = durations.keys.max() {
            for offset in 0..<30 {
                guard let d = cal.date(byAdding: .day, value: -offset, to: last) else { continue }
                if map[d] == nil {
                    map[d] = .rest
                }
            }
        }

        DispatchQueue.main.async {
            self.trainingTypesByDay = map
        }
    }

    private func updateLoad7d() {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        guard let start = cal.date(byAdding: .day, value: -6, to: today) else { return }

        let e = epocPerDay.filter { $0.key >= start && $0.key <= today }
                          .map(\.value).reduce(0, +)
        let t = trimpPerDay.filter { $0.key >= start && $0.key <= today }
                            .map(\.value).reduce(0, +)

        DispatchQueue.main.async {
            self.trainingLoad7d = e + t
        }
    }

    func calculateTrainingLoad(for date: Date) -> Double {
        (epocPerDay[date] ?? 0) + (trimpPerDay[date] ?? 0)
    }

    func getWeeklyEPOCTotal() -> Double {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        guard let start = cal.date(byAdding: .day, value: -6, to: today) else { return 0 }

        return epocPerDay
            .filter { $0.key >= start && $0.key <= today }
            .map(\.value)
            .reduce(0, +)
    }

    func getAverageEPOCOverLastWeeks(weeks: Int = 6) -> Double {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var weeklyTotals: [Double] = []

        for i in 0..<weeks {
            guard let weekStart = calendar.date(byAdding: .day, value: -7 * (i + 1) + 1, to: today),
                  let weekEnd = calendar.date(byAdding: .day, value: -7 * i, to: today) else { continue }

            let weekEPOCs = epocPerDay
                .filter { $0.key >= weekStart && $0.key <= weekEnd && $0.value > 0 }
                .map(\.value)

            weeklyTotals.append(weekEPOCs.reduce(0, +))
        }

        return weeklyTotals.reduce(0, +) / Double(weeks)
    }

    func calculateATL(for date: Date) -> Double {
        calculateExponentialAverage(for: date, overDays: 7, decay: 0.9)
    }

    func calculateCTL(for date: Date) -> Double {
        calculateExponentialAverage(for: date, overDays: 42, decay: 0.975)
    }

    private func calculateExponentialAverage(
        for date: Date,
        overDays range: Int,
        decay: Double
    ) -> Double {
        var sum: Double = 0
        var weight: Double = 1
        var totalWeight: Double = 0

        for i in 0..<range {
            guard let d = Calendar.current.date(byAdding: .day, value: -i, to: date) else { continue }
            let load = calculateTrainingLoad(for: d)
            sum += load * weight
            totalWeight += weight
            weight *= decay
        }

        return totalWeight > 0 ? sum / totalWeight : 0
    }
}
