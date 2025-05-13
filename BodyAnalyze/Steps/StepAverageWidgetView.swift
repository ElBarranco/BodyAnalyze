//
//  StepAverageWidgetView.swift
//  BodyAnalyze
//
//  Created by Lionel Barranco on 30/04/2025.
//

import SwiftUI

/// Widget affichant la moyenne quotidienne de pas sur les 7 derniers jours
struct StepAverageWidgetView: View {
    @EnvironmentObject var healthVM: HealthViewModel

    /// Moyenne arrondie des pas sur 7 jours
    private var averageSteps: Int {
        Int(healthVM.stepVM.averageSteps.rounded())
    }

    var body: some View {
        VStack(spacing: 12) {
            Text("🚶‍♂️ Pas en moyenne")
                .font(.headline)

            Text("\(averageSteps)")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundColor(.blue)

            Text("pas/jour sur 7 jours")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

struct StepAverageWidgetView_Previews: PreviewProvider {
    static var previews: some View {
        StepAverageWidgetView()
            .environmentObject(sampleHealthVM)
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .previewLayout(.sizeThatFits)
    }

    private static var sampleHealthVM: HealthViewModel = {
        let vm = HealthViewModel()
        let today = Calendar.current.startOfDay(for: Date())
        let days = (0...6).map { Calendar.current.date(byAdding: .day, value: -$0, to: today)! }
        vm.stepVM.stepsPerDay = Dictionary(uniqueKeysWithValues: days.map { ($0, 5000) })
        vm.stepVM.runningStepsPerDay = Dictionary(uniqueKeysWithValues: days.map { ($0, 1200) })
        vm.stepVM.averageSteps = 5000
        return vm
    }()
}
