import Foundation
import Combine

/// ViewModel principal orchestrant HeartMetricsViewModel, CalorieViewModel, TrainingViewModel et StepCountViewModel
class HealthViewModel: ObservableObject {
    // MARK: - Sub-view models
    @Published var heartVM    = HeartMetricsViewModel()
    @Published var calorieVM  = CalorieViewModel()
    @Published var trainingVM = TrainingViewModel()
    @Published var stepVM     = StepCountViewModel()

    // MARK: - UI / Chargement
    @Published var isLoading: Bool = false

    // MARK: - Données globales
    @Published var currentRange: TimeRange = .month {
        didSet { loadAllData() }
    }
    @Published var lastUpdated: Date?

    // MARK: - Init
    init() {
        loadAllData()
    }

    // MARK: - Chargement global des données
    func loadAllData() {
        isLoading = true
        // Multi-tâche asynchrone pour ne pas bloquer l'interface
        Task {
            await withTaskGroup(of: Void.self) { group in
                // ❤️ Données cardiaques
                group.addTask {
                    self.heartVM.loadHeartData(range: self.currentRange)
                }

                // 🔥 Calories
                group.addTask {
                    self.calorieVM.loadCaloriesData(range: self.currentRange)
                }

                // 🏋️ Entraînement – charger les 6 dernières semaines pour graphiques swipe
                group.addTask {
                    self.trainingVM.loadRecentWeeksData(weeks: 6)
                }

                // 👣 Pas et course
                group.addTask {
                    self.stepVM.loadStepsData(range: self.currentRange)
                    self.stepVM.loadRunningStepsData(range: self.currentRange)
                }
            }

            // 🕒 Mettre à jour les métadonnées sur le thread principal
            await MainActor.run {
                self.lastUpdated = Date()
                self.isLoading = false
            }
        }
    }
}
