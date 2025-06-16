import Foundation
import HealthKit

class TrainingViewModel: ObservableObject {
    @Published var workoutCount: Int = 0
    @Published var epocPerDay: [Date: Double] = [:]
    @Published var trimpPerDay: [Date: Double] = [:]
    @Published var trainingTypesByDay: [Date: TrainingType] = [:]
    @Published var disciplineByDay: [Date: WorkoutDiscipline] = [:]
    @Published var disciplineDistribution: [WorkoutDiscipline: Int] = [:] 

    @Published var trainingLoad7d: Double = 0.0
    @Published var maxHeartRate: Double = 190.0
    @Published var restingHR: Double = 60.0
    @Published var isMale: Bool = true
    @Published var currentWeekStart: Date = Calendar.current.startOfWeek(for: Date())
    @Published var vo2max: Double = 0.0
    
    @Published var weeklyWorkoutMinutes: Int = 0
    
    @Published var weeklyRunningDistance: Double = 0.0
    @Published var weeklyRunningDistances: [WeekDistance] = []

    private let courseManager = CourseManager()
    
    private let healthStore = HKHealthStore()
    private let healthManager = HealthManager()
    private var authorized = false
    
    func loadWeeklyRunningDistance() {
        courseManager.getWeeklyRunningDistance { distance in
            DispatchQueue.main.async { self.weeklyRunningDistance = distance }
        }
    }

    func loadWeeklyRunningDistances() {
        courseManager.getWeeklyRunningDistances(weeks: 6) { distances in
            DispatchQueue.main.async { self.weeklyRunningDistances = distances }
        }
    }

    func loadRecentWeeksData(weeks: Int = 6) {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        self.currentWeekStart = cal.startOfWeek(for: today)

        guard let start = cal.date(byAdding: .day, value: -7 * weeks, to: today) else { return }
        loadTrainingData(from: start, to: today)
        
        // 🏃‍♂️ Charge les distances de course à pied
        loadWeeklyRunningDistance()
        loadWeeklyRunningDistances()
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
            self.calculateDisciplineDistribution(for: workouts) // ✅ Ajout pour camembert

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
            default:           discipline = .other
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

    func loadVO2Max() {
        healthManager.fetchVO2Max { value in
            DispatchQueue.main.async {
                self.vo2max = value ?? 0.0
            }
        }
    }
    
    func calculateTrainingLoad(for date: Date) -> Double {
        let startOfDay = Calendar.current.startOfDay(for: date)
        let epoc = epocPerDay[startOfDay] ?? 0
        let trimp = trimpPerDay[startOfDay] ?? 0
        print("📅 \(startOfDay.formatted()) ➤ EPOC: \(epoc), TRIMP: \(trimp)")
        return epoc + trimp
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
    
    func calculateDisciplineDistribution(for workouts: [HKWorkout]) {
        var distribution: [WorkoutDiscipline: Int] = [:]
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        guard let monthAgo = cal.date(byAdding: .month, value: -1, to: today) else { return }

        for workout in workouts where workout.startDate >= monthAgo {
            let discipline: WorkoutDiscipline
            switch workout.workoutActivityType {
            case .running: discipline = .running
            case .walking: discipline = .walking
            case .hiking: discipline = .hiking
            case .cycling: discipline = .cycling
            case .swimming: discipline = .swimming
            case .yoga: discipline = .yoga
            case .traditionalStrengthTraining, .functionalStrengthTraining: discipline = .strength
            case .highIntensityIntervalTraining: discipline = .hiit
            case .mindAndBody: discipline = .mobility
            default: discipline = .other
            }

            distribution[discipline, default: 0] += 1
        }

        DispatchQueue.main.async {
            self.disciplineDistribution = distribution
        }
    }
    
    /// Charge le total de minutes de workouts des 7 derniers jours
    func loadWeeklyWorkoutMinutes() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        let workoutType = HKObjectType.workoutType()
        let now = Date()
        guard let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: now) else { return }

        let predicate = HKQuery.predicateForSamples(withStart: weekAgo, end: now, options: .strictStartDate)
        let query = HKSampleQuery(sampleType: workoutType,
                                  predicate: predicate,
                                  limit: HKObjectQueryNoLimit,
                                  sortDescriptors: nil) { [weak self] _, samples, error in
            guard let self = self,
                  error == nil,
                  let workouts = samples as? [HKWorkout] else { return }

            let totalMinutes = workouts.reduce(0) { sum, w in sum + Int(w.duration / 60) }
            DispatchQueue.main.async { self.weeklyWorkoutMinutes = totalMinutes }
        }
        healthStore.execute(query)
    }
    
    /// Formatte en "H h MM" ou "MM min"
    var weeklyWorkoutDisplay: String {
        let minutes = weeklyWorkoutMinutes
        if minutes >= 60 {
            let h = minutes / 60
            let m = minutes % 60
            return String(format: "%dh%02d", h, m)
        } else {
            return "\(minutes) min"
        }
    }
    
    /// Moyenne des distances sur 6 semaines
    var averageWeeklyDistance: Double {
        let total = weeklyRunningDistances.map(\.distance).reduce(0, +)
        return weeklyRunningDistances.isEmpty ? 0 : total / Double(weeklyRunningDistances.count)
    }
}
