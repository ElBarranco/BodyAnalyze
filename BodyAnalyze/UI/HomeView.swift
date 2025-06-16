import SwiftUI

struct HomeView: View {
    @EnvironmentObject var healthVM: HealthViewModel

    var body: some View {
        NavigationWrapperView(title: "Accueil 🏠") {
            ScrollView {
                VStack(spacing: 16) {

                    // 📊 Calcul des 4 composantes
                    let hrv = healthVM.heartVM.hrvScore(sdnn: healthVM.heartVM.hrvValue)
                    let rhr = restingHRScore(healthVM.heartVM.restingHR)
                    let act = activityScore(stepVM: healthVM.stepVM, calorieVM: healthVM.calorieVM)
                    let training = trainingLoadScore(load: healthVM.trainingVM.trainingLoad7d)

                    let globalScore = globalWellbeingScore(hrv: hrv, rhr: rhr, activity: act, training: training)
                    let color = scoreColor(for: globalScore)
                    let vo2 = vo2maxScore(healthVM.trainingVM.vo2max)

                    // 💯 Carte score global
                    VStack(spacing: 8) {
                        Text("Forme du jour")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        Text("\(Int(globalScore)) / 100")
                            .font(.system(size: 42, weight: .bold))
                            .foregroundColor(color)

                        Circle()
                            .fill(color)
                            .frame(width: 12, height: 12)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.secondarySystemBackground))
                    )

                    // 🔍 Détail des composantes
                    TileGrid {
                        Tile {
                            WellbeingScoreTile(
                                title: "🧠 VFC",
                                score: hrv,
                                color: .blue
                            )
                        }.wrapped()

                        Tile {
                            WellbeingScoreTile(
                                title: "❤️ BPM repos",
                                score: rhr,
                                color: .red
                            )
                        }.wrapped()

                        
                        Tile {
                            WellbeingScoreTile(
                                title: "🚶 Activité",
                                score: act,
                                color: .green
                            )
                        }.wrapped()

                        Tile {
                            WellbeingScoreTile(
                                title: "🏋️ Charge",
                                score: training,
                                color: .purple
                            )
                        }.wrapped()
                    }
                    TileGrid {
                        
                        Tile(span: .half) {
                            VO2MaxArcView(vo2max: healthVM.trainingVM.vo2max)
                        }.wrapped()
                    }

                    WeeklyExerciseView()
                        .environmentObject(healthVM)

                }
                .padding()
            }
        }
    }

    // MARK: - Scoring helpers

    private func restingHRScore(_ bpm: Double) -> Double {
        if bpm >= 80 { return 0.0 }
        else if bpm >= 70 { return 3.0 }
        else if bpm >= 60 { return 6.0 }
        else if bpm >= 50 { return 8.0 }
        else { return 10.0 }
    }

    private func activityScore(stepVM: StepCountViewModel, calorieVM: CalorieViewModel) -> Double {
        var score = 0.0
        let goal = stepVM.dailyStepGoal ?? 8000
        let steps = stepVM.todaySteps
        score += min(Double(steps) / Double(goal), 1.0) * 4.0

        if let trend = calorieVM.neatTrend {
            switch trend.status {
            case .moreActive: score += 3.5
            case .stable: score += 2.5
            case .lessActive: score += 1.0
            }
        } else {
            score += 2.0
        }

        let exposure = stepVM.todayLightExposure
        if exposure >= 30 { score += 2.5 }
        else if exposure >= 10 { score += 1.5 }
        else { score += 0.5 }

        return min(score, 10.0)
    }

    private func vo2maxScore(_ value: Double) -> (score: Double, color: Color) {
        switch value {
        case ..<30: return (2.0, .red)
        case 30..<40: return (4.0, .orange)
        case 40..<50: return (6.5, .yellow)
        case 50..<60: return (8.5, .green)
        default:     return (10.0, .blue)
        }
    }
    
    private func trainingLoadScore(load: Double) -> Double {
        switch load {
        case ..<100: return 2.0
        case 100..<250: return 5.0
        case 250..<500: return 8.0
        case 500..<700: return 6.0
        default: return 3.0
        }
    }

    private func globalWellbeingScore(hrv: Double, rhr: Double, activity: Double, training: Double) -> Double {
        let raw = (hrv + rhr + activity + training) / 40.0 * 100.0
        return min(max(raw, 0), 100.0)
    }

    private func scoreColor(for score: Double) -> Color {
        switch score {
        case 0..<40: return .red
        case 40..<55: return .orange
        case 55..<70: return .yellow
        case 70..<85: return .green
        case 85..<95: return .blue
        default: return .white
        }
    }
}
