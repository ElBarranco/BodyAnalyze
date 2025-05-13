import HealthKit

typealias HRVSample = (date: Date, value: Double)

/// Plage de temps pour les requêtes HealthKit
enum TimeRange {
    case week
    case month
    case custom(start: Date, end: Date)
}

extension TimeRange {
    /// Date de début de la plage
    var startDate: Date {
        let cal = Calendar.current
        let now = Date()
        switch self {
        case .week:
            let comps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
            return cal.date(from: comps)!  // début du lundi de la semaine en cours
        case .month:
            return cal.date(byAdding: .day, value: -30, to: now)!  // 30 jours avant aujourd'hui
        case .custom(let start, _):
            return start
        }
    }

    /// Date de fin de la plage
    var endDate: Date {
        switch self {
        case .custom(_, let end):
            return end
        default:
            return Date()  // maintenant
        }
    }
}

/// Manager central pour toutes les requêtes HealthKit
class HealthManager {
    let healthStore = HKHealthStore()

    /// Types à lire dans HealthKit
    var readTypes: Set<HKObjectType> {
        var types: Set<HKObjectType> = [
            .workoutType(),
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .restingHeartRate)!,
            HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .basalEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKObjectType.quantityType(forIdentifier: .vo2Max)!,
            HKObjectType.quantityType(forIdentifier: .runningGroundContactTime)!,
            HKObjectType.quantityType(forIdentifier: .runningStrideLength)!,
            HKObjectType.characteristicType(forIdentifier: .dateOfBirth)!,
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!
        ]
        if let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) {
            types.insert(stepType)
        }
        return types
    }

    /// Demande d'autorisation HealthKit
    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        healthStore.requestAuthorization(toShare: [], read: readTypes, completion: completion)
    }
    
    // MARK: - Caractéristiques utilisateur (sexe, âge, poids)

    func loadUserCharacteristics(completion: @escaping (_ sex: String?, _ age: Int?, _ weight: Double?) -> Void) {
        var userSex: String? = nil
        var userAge: Int? = nil
        var userWeight: Double? = nil
        let group = DispatchGroup()

        // Sexe
        do {
            let biologicalSex = try healthStore.biologicalSex()
            switch biologicalSex.biologicalSex {
            case .female: userSex = "Femme"
            case .male:   userSex = "Homme"
            default: break
            }
        } catch {
            print("Erreur sexe : \(error)")
        }

        // Âge
        do {
            let birthDate = try healthStore.dateOfBirthComponents()
            if let year = birthDate.year {
                let currentYear = Calendar.current.component(.year, from: Date())
                userAge = currentYear - year
            }
        } catch {
            print("Erreur âge : \(error)")
        }

        // Poids
        group.enter()
        if let weightType = HKObjectType.quantityType(forIdentifier: .bodyMass) {
            let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
            let query = HKSampleQuery(sampleType: weightType, predicate: nil, limit: 1, sortDescriptors: [sort]) { _, samples, _ in
                if let sample = samples?.first as? HKQuantitySample {
                    userWeight = sample.quantity.doubleValue(for: .gramUnit(with: .kilo))
                }
                group.leave()
            }
            healthStore.execute(query)
        } else {
            group.leave()
        }

        group.notify(queue: .main) {
            completion(userSex, userAge, userWeight)
        }
    }

    // MARK: - Requêtes quotidiennes

    /// Fréquence cardiaque de repos (moyenne journalière)
    func fetchRestingHeartRate(completion: @escaping (Double?) -> Void) {
        guard let type = HKObjectType.quantityType(forIdentifier: .restingHeartRate) else {
            completion(nil); return
        }
        let start = Calendar.current.startOfDay(for: Date())
        let pred = HKQuery.predicateForSamples(withStart: start, end: Date(), options: .strictStartDate)
        let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: pred, options: .discreteAverage) { _, stats, _ in
            let hr = stats?.averageQuantity()?.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
            completion(hr)
        }
        healthStore.execute(query)
    }

    func fetchWalkingRunningDistancePerWeek(
        range: TimeRange,
        completion: @escaping ([Date: Double]) -> Void
    ) {
        guard let type = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning) else {
            completion([:])
            return
        }

        let cal = Calendar.current
        let start = range.startDate
        let end = range.endDate

        // Anchor au début de la semaine
        let anchor = cal.date(
            from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: start)
        )!
        let interval = DateComponents(weekOfYear: 1)
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: [])

        let query = HKStatisticsCollectionQuery(
            quantityType: type,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum,
            anchorDate: anchor,
            intervalComponents: interval
        )

        query.initialResultsHandler = { _, results, error in
            if let _ = error {
                completion([:])
                return
            }

            var map: [Date: Double] = [:]
            results?.enumerateStatistics(from: start, to: end) { stat, _ in
                let week = cal.date(
                    from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: stat.startDate)
                )!
                let value = stat.sumQuantity()?.doubleValue(for: .meterUnit(with: .kilo)) ?? 0
                map[week] = value
            }

            // Envoi des données sans debug prints
            DispatchQueue.main.async {
                completion(map)
            }
        }

        healthStore.execute(query)
    }
    
    /// Calories actives et basales par jour sur une plage donnée
    func fetchCaloriesBreakdownPerDay(
        for range: TimeRange,
        completion: @escaping ([Date: Double], [Date: Double]) -> Void
    ) {
        guard let activeType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned),
              let basalType  = HKObjectType.quantityType(forIdentifier: .basalEnergyBurned)
        else {
            completion([:], [:]); return
        }

        let cal   = Calendar.current
        let start = range.startDate
        let end   = range.endDate
        let anchor = cal.startOfDay(for: start)
        let interval = DateComponents(day: 1)
        let group = DispatchGroup()
        var mapA: [Date: Double] = [:], mapB: [Date: Double] = [:]

        // Active
        group.enter()
        let queryA = HKStatisticsCollectionQuery(
            quantityType: activeType,
            quantitySamplePredicate: HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate),
            options: .cumulativeSum,
            anchorDate: anchor,
            intervalComponents: interval
        )
        queryA.initialResultsHandler = { _, result, _ in
            result?.enumerateStatistics(from: start, to: end) { stat, _ in
                let day = cal.startOfDay(for: stat.startDate)
                mapA[day] = stat.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
            }
            group.leave()
        }
        healthStore.execute(queryA)

        // Basal
        group.enter()
        let queryB = HKStatisticsCollectionQuery(
            quantityType: basalType,
            quantitySamplePredicate: HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate),
            options: .cumulativeSum,
            anchorDate: anchor,
            intervalComponents: interval
        )
        queryB.initialResultsHandler = { _, result, _ in
            result?.enumerateStatistics(from: start, to: end) { stat, _ in
                let day = cal.startOfDay(for: stat.startDate)
                mapB[day] = stat.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
            }
            group.leave()
        }
        healthStore.execute(queryB)

        group.notify(queue: .main) {
            completion(mapA, mapB)
        }
    }

    // MARK: - Workouts

    /// Récupère les workouts entre deux dates
    func fetchWorkouts(
        from startDate: Date,
        to endDate: Date,
        completion: @escaping ([HKWorkout]) -> Void
    ) {
        let pred = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
        let query = HKSampleQuery(sampleType: .workoutType(), predicate: pred, limit: HKObjectQueryNoLimit, sortDescriptors: [sort]) { _, samples, _ in
            let all = (samples as? [HKWorkout]) ?? []
            completion(all.filter { ![.walking, .yoga, .mindAndBody].contains($0.workoutActivityType) })
        }
        healthStore.execute(query)
    }

    /// Variabilité cardiaque jour par jour (min/max) sur une plage donnée
    func analyzeVFCMinMaxPerDay(
        for range: TimeRange,
        completion: @escaping ([Date: Double], [Date: Double]) -> Void
    ) {
        guard let type = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else {
            completion([:], [:]); return
        }
        let cal   = Calendar.current
        let start = range.startDate
        let end   = range.endDate
        let pred  = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let sort  = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        let query = HKSampleQuery(sampleType: type, predicate: pred, limit: HKObjectQueryNoLimit, sortDescriptors: [sort]) { _, samples, _ in
            let arr = (samples as? [HKQuantitySample]) ?? []
            var maxMap: [Date: Double] = [:], minMap: [Date: Double] = [:]
            arr.forEach {
                let day = cal.startOfDay(for: $0.startDate)
                let v = $0.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli))
                maxMap[day] = max(v, maxMap[day] ?? 0)
                minMap[day] = min(v, minMap[day] ?? .greatestFiniteMagnitude)
            }
            completion(maxMap, minMap)
        }
        healthStore.execute(query)
    }

    /// Zones de fréquence cardiaque sur un ensemble de workouts
    func analyzeHeartRateZones(
        for workouts: [HKWorkout],
        maxHR: Double,
        restHR: Double,
        completion: @escaping ([Int: TimeInterval]) -> Void
    ) {
        var zones: [Int: TimeInterval] = [:]
        let group = DispatchGroup()
        workouts.forEach { w in
            group.enter()
            guard let hrType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
                group.leave(); return
            }
            let pred = HKQuery.predicateForSamples(withStart: w.startDate, end: w.endDate, options: .strictStartDate)
            let query = HKSampleQuery(sampleType: hrType, predicate: pred, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, _ in
                let arr = (samples as? [HKQuantitySample]) ?? []
                for i in 1..<arr.count {
                    let prev = arr[i-1], curr = arr[i]
                    let dt  = curr.startDate.timeIntervalSince(prev.startDate)
                    let bpm = prev.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
                    let z   = Self.getZone(for: bpm, maxHR: maxHR, restHR: restHR)
                    zones[z, default: 0] += dt
                }
                group.leave()
            }
            healthStore.execute(query)
        }
        group.notify(queue: .main) {
            completion(zones)
        }
    }

    // MARK: - HRV

    /// Échantillons de variabilité cardiaque sur une plage donnée
    func fetchHRVSamples(
        for range: TimeRange,
        completion: @escaping ([HRVSample]) -> Void
    ) {
        guard let type = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else {
            completion([]); return
        }
        let start = range.startDate
        let end   = range.endDate
        let pred  = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let sort  = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        let query = HKSampleQuery(sampleType: type, predicate: pred, limit: HKObjectQueryNoLimit, sortDescriptors: [sort]) { _, samples, _ in
            let arr = (samples as? [HKQuantitySample]) ?? []
            let results = arr.map { stat in
                HRVSample(date: stat.startDate,
                          value: stat.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli)))
            }
            completion(results)
        }
        healthStore.execute(query)
    }

    // MARK: - TRIMP

    /// TRIMP par workout
    func analyzeTRIMPPerWorkout(
        for workouts: [HKWorkout],
        restingHR: Double,
        maxHR: Double,
        isMale: Bool,
        completion: @escaping ([Date: Double]) -> Void
    ) {
        var map: [Date: Double] = [:]
        let group = DispatchGroup()
        workouts.forEach { w in
            group.enter()
            guard let hrType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
                group.leave(); return
            }
            let pred = HKQuery.predicateForSamples(withStart: w.startDate, end: w.endDate, options: .strictStartDate)
            let query = HKSampleQuery(sampleType: hrType, predicate: pred, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, _ in
                let arr = (samples as? [HKQuantitySample]) ?? []
                let duration = w.duration/60
                let avgHR    = arr.map { $0.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute())) }.reduce(0, +)/Double(arr.count)
                let r        = (avgHR - restingHR)/(maxHR - restingHR)
                let coeff    = isMale ? 0.64 : 0.86
                let expn     = isMale ? 1.92 : 1.67
                let trimp    = duration * r * coeff * pow(M_E, expn * r)
                let day      = Calendar.current.startOfDay(for: w.startDate)
                map[day, default: 0] += trimp
                group.leave()
            }
            healthStore.execute(query)
        }
        group.notify(queue: .main) {
            completion(map)
        }
    }

    // MARK: - Pas

    /// Total de pas par jour sur une plage donnée
    func fetchStepCountPerDay(
        for range: TimeRange,
        completion: @escaping ([Date: Int]) -> Void
    ) {
        guard let type = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            completion([:]); return
        }
        let cal   = Calendar.current
        let start = range.startDate
        let end   = range.endDate
        let anchor = cal.startOfDay(for: start)
        let interval = DateComponents(day: 1)
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)

        let query = HKStatisticsCollectionQuery(
            quantityType: type,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum,
            anchorDate: anchor,
            intervalComponents: interval
        )
        query.initialResultsHandler = { _, result, _ in
            var map: [Date: Int] = [:]
            result?.enumerateStatistics(from: start, to: end) { stat, _ in
                let day = cal.startOfDay(for: stat.startDate)
                map[day] = Int(stat.sumQuantity()?.doubleValue(for: .count()) ?? 0)
            }
            DispatchQueue.main.async {
                completion(map)
            }
        }
        healthStore.execute(query)
    }

    /// Pas durant les activités running/hiking/cross-country sur une plage
    func fetchRunningStepCountPerDay(
        for range: TimeRange,
        completion: @escaping ([Date: Int]) -> Void
    ) {
        let workoutType    = HKObjectType.workoutType()
        let activityTypes: [HKWorkoutActivityType] = [.running, .hiking, .crossCountrySkiing]
        let workoutPred    = NSCompoundPredicate(orPredicateWithSubpredicates: activityTypes.map {
            HKQuery.predicateForWorkouts(with: $0)
        })
        let sort           = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
        let workoutQuery   = HKSampleQuery(sampleType: workoutType, predicate: workoutPred, limit: HKObjectQueryNoLimit, sortDescriptors: [sort]) { _ , samples, _ in
            let workouts = (samples as? [HKWorkout]) ?? []
            let cal   = Calendar.current
            var map: [Date: Int] = [:]
            let group = DispatchGroup()
            for w in workouts where w.startDate >= range.startDate && w.endDate <= range.endDate {
                group.enter()
                guard let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
                    group.leave(); continue
                }
                let stepPred = HKQuery.predicateForSamples(withStart: w.startDate, end: w.endDate, options: .strictStartDate)
                let stepsQuery = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: stepPred, options: .cumulativeSum) { _, result, _ in
                    let count = Int(result?.sumQuantity()?.doubleValue(for: .count()) ?? 0)
                    let day   = cal.startOfDay(for: w.startDate)
                    map[day, default: 0] += count
                    group.leave()
                }
                self.healthStore.execute(stepsQuery)
            }
            group.notify(queue: .main) {
                completion(map)
            }
        }
        healthStore.execute(workoutQuery)
    }

    // MARK: - EPOC

    /// Calcul de l'EPOC par jour d'après les workouts
    func analyzeEPOCPerDayV2(
        for workouts: [HKWorkout],
        maxHeartRate: Double,
        completion: @escaping ([Date: Double]) -> Void
    ) {
        var map: [Date: Double] = [:]
        let cal = Calendar.current
        let group = DispatchGroup()
        workouts.forEach { w in
            group.enter()
            guard let hrType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
                group.leave(); return
            }
            let pred = HKQuery.predicateForSamples(withStart: w.startDate, end: w.endDate, options: .strictStartDate)
            let query = HKSampleQuery(sampleType: hrType, predicate: pred, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, _ in
                let arr = (samples as? [HKQuantitySample]) ?? []
                var score: Double = 0, prevE: Double = 0
                for i in 1..<arr.count {
                    let p = arr[i-1], c = arr[i]
                    let dt  = c.startDate.timeIntervalSince(p.startDate)
                    let bp  = c.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
                    let pp  = p.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
                    let pct = bp/maxHeartRate
                    let varn = abs(bp-pp)/max(pp, 1)
                    let coeff = Self.getDynamicEPOCCoefficient(hrPercent: pct, variation: varn)
                    let delta = coeff * (dt/60)
                    prevE = max(0, prevE + delta)
                    if pct < 0.6 { prevE *= 0.90 }
                    score += delta
                }
                let day = cal.startOfDay(for: w.startDate)
                map[day, default: 0] += score
                group.leave()
            }
            healthStore.execute(query)
        }
        group.notify(queue: .main) {
            completion(map)
        }
    }

    /// Total EPOC sur la dernière semaine d'après un map jour->valeur
    func getWeeklyEPOCTotal(from epocPerDay: [Date: Double]) -> Double {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let start = cal.date(byAdding: .day, value: -6, to: today)!
        return epocPerDay
            .filter { $0.key >= start && $0.key <= today }
            .reduce(0) { $0 + $1.value }
    }

    // MARK: - Utilitaires

    private static func getDynamicEPOCCoefficient(hrPercent: Double, variation: Double) -> Double {
        switch hrPercent {
        case ..<0.6: return 0.2
        case ..<0.7: return 0.7 + variation * 0.2
        case ..<0.8: return 1.5 + variation * 0.5
        case ..<0.9: return 2.5 + variation * 1.0
        default:     return 4.0 + variation * 1.5
        }
    }

    private static func getZone(for bpm: Double, maxHR: Double, restHR: Double) -> Int {
        let reserve = maxHR - restHR
        guard reserve > 0 else { return 1 }
        let pct = (bpm - restHR) / reserve
        switch pct {
        case ..<0.60: return 1
        case ..<0.70: return 2
        case ..<0.80: return 3
        case ..<0.90: return 4
        default:      return 5
        }
    }

    /// Date de naissance (Characteristic)
    func fetchBirthday(completion: @escaping (Date?) -> Void) {
        do {
            let comps = try healthStore.dateOfBirthComponents()
            completion(Calendar.current.date(from: comps))
        } catch {
            completion(nil)
        }
    }

    /// Dernier HRV (plus récent)
    func fetchLatestHRV(completion: @escaping (Double?, Date?) -> Void) {
        guard let type = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else {
            completion(nil, nil); return
        }
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sort]) { _, res, _ in
            guard let s = res?.first as? HKQuantitySample else {
                completion(nil, nil); return
            }
            let v = s.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli))
            completion(v, s.endDate)
        }
        healthStore.execute(query)
    }
}
