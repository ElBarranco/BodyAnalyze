import SwiftUI

struct StepDailyProgressWidgetView: View {
    @EnvironmentObject var healthVM: HealthViewModel

    var body: some View {
        let current = healthVM.stepVM.todaySteps
        let goal = healthVM.stepVM.dailyStepGoal ?? 10000  // Valeur par défaut
        let progress = min(Double(current) / Double(goal), 1.0)
        let remaining = max(goal - current, 0)

        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("📍 Progression du jour")
                    .font(.headline)
                Spacer()
                if current >= goal {
                    Text("🎉 Objectif atteint !")
                        .foregroundColor(.green)
                        .fontWeight(.bold)
                } else {
                    Text("\(remaining) pas restants")
                        .foregroundColor(.secondary)
                }
            }

            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: current >= goal ? .green : .blue))
                .scaleEffect(x: 1, y: 4, anchor: .center)
                .animation(.easeInOut, value: progress)

            HStack {
                Text("\(current) pas")
                    .font(.subheadline)
                    .foregroundColor(.primary)

            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}
