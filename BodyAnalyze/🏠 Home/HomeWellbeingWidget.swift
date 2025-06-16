import SwiftUI

struct HomeWellbeingWidget: View {
    @ObservedObject var heartVM: HeartMetricsViewModel
    @ObservedObject var stepVM: StepCountViewModel
    @ObservedObject var calorieVM: CalorieViewModel

    var body: some View {
        let hrv = heartVM.hrvScore(sdnn: heartVM.hrvValue)
        let rhr = restingHRScore(heartVM.restingHR)
        let activity = activityScore(stepVM: stepVM, calorieVM: calorieVM)
        let score = globalWellbeingScore(hrv: hrv, rhr: rhr, activity: activity)
        let color = scoreColor(for: score)

        VStack(spacing: 8) {
            Text("Forme du jour")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("\(Int(score)) / 100")
                .font(.system(size: 42, weight: .bold))
                .foregroundColor(color)

            // 🔍 Mini barres explicatives
            MiniWellbeingBreakdown(
                hrvScore: hrv,
                rhrScore: rhr,
                activityScore: activity
            )

            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private func globalWellbeingScore(hrv: Double, rhr: Double, activity: Double) -> Double {
        // Pondération égale pour chaque composante
        let raw = (hrv + rhr + activity) / 30.0 * 100.0
        return min(max(raw, 0), 100)
    }

    private func restingHRScore(_ bpm: Double) -> Double {
        if bpm >= 80 { return 0.0 }
        else if bpm >= 70 { return 3.0 }
        else if bpm >= 60 { return 6.0 }
        else if bpm >= 50 { return 8.0 }
        else { return 10.0 }
    }

    private func activityScore(stepVM: StepCountViewModel, calorieVM: CalorieViewModel) -> Double {
        var score = 0.0

        // 🎯 Pas
        let goal = stepVM.dailyStepGoal ?? 8000
        let steps = stepVM.todaySteps
        let stepRatio = min(Double(steps) / Double(goal), 1.0)
        score += stepRatio * 4.0

        // 🔥 NEAT
        if let trend = calorieVM.neatTrend {
            switch trend.status {
            case .moreActive: score += 3.5
            case .stable: score += 2.5
            case .lessActive: score += 1.0
            }
        } else {
            score += 2.0
        }

        // 🌞 Lumière
        let exposure = stepVM.todayLightExposure
        if exposure >= 30 {
            score += 2.5
        } else if exposure >= 10 {
            score += 1.5
        } else {
            score += 0.5
        }

        return min(score, 10.0)
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
