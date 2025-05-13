//
//  StepTrendWidgetView.swift
//  BodyAnalyze
//
//  Created by Lionel Barranco on 30/04/2025.
//

import SwiftUI

/// Widget indiquant la tendance des pas (semaine en cours vs semaine précédente)
struct StepTrendWidgetView: View {
    @EnvironmentObject var healthVM: HealthViewModel

    private enum Trend {
        case up, down, flat

        var symbol: String {
            switch self {
            case .up:   return "arrow.up"
            case .down: return "arrow.down"
            case .flat: return "minus"
            }
        }

        var color: Color {
            switch self {
            case .up:   return .green
            case .down: return .red
            case .flat: return .gray
            }
        }

        var label: String {
            switch self {
            case .up:   return "En hausse"
            case .down: return "En baisse"
            case .flat: return "Stable"
            }
        }
    }

    // MARK: - Calcul de la tendance
    private var trend: Trend {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())

        // Pas des 7 derniers jours (aujourd'hui inclus)
        let last7 = (0..<7).compactMap { cal.date(byAdding: .day, value: -$0, to: today) }
        let prev7 = (7..<14).compactMap { cal.date(byAdding: .day, value: -$0, to: today) }

        let thisTotal = last7.map { healthVM.stepVM.stepsPerDay[$0] ?? 0 }.reduce(0, +)
        let lastTotal = prev7.map { healthVM.stepVM.stepsPerDay[$0] ?? 0 }.reduce(0, +)

        switch thisTotal.compare(to: lastTotal, tolerance: 0.05) {
        case .greater: return .up
        case .less:    return .down
        case .equal:   return .flat
        }
    }

    // MARK: - Calcul du pourcentage d'évolution
    private var percentageChange: Double? {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())

        let last7 = (0..<7).compactMap { cal.date(byAdding: .day, value: -$0, to: today) }
        let prev7 = (7..<14).compactMap { cal.date(byAdding: .day, value: -$0, to: today) }

        let thisTotal = last7.map { healthVM.stepVM.stepsPerDay[$0] ?? 0 }.reduce(0, +)
        let lastTotal = prev7.map { healthVM.stepVM.stepsPerDay[$0] ?? 0 }.reduce(0, +)

        guard lastTotal > 0 else { return nil }

        return (Double(thisTotal - lastTotal) / Double(lastTotal)) * 100
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: trend.symbol)
                .resizable()
                .scaledToFit()
                .frame(width: 36, height: 36)
                .foregroundColor(trend.color)

            VStack(alignment: .leading, spacing: 4) {
                Text(trend.label)
                    .font(.headline)

                Text("vs semaine précédente")
                    .font(.caption)
                    .foregroundColor(.secondary)

                if let percent = percentageChange {
                    Text(String(format: "%+.1f%%", percent))
                        .font(.caption)
                        .foregroundColor(trend.color)
                }
            }
        }
    }
}

private extension Int {
    enum Comparison { case less, equal, greater }

    /// Compare self to another value with relative tolerance
    func compare(to other: Int, tolerance: Double) -> Comparison {
        guard other != 0 else { return .equal }
        let delta = Double(self - other) / Double(other)
        if delta > tolerance { return .greater }
        if delta < -tolerance { return .less }
        return .equal
    }
}

// MARK: - Preview
struct StepTrendWidgetView_Previews: PreviewProvider {
    static var previews: some View {
        StepTrendWidgetView()
            .environmentObject(sampleHealthVM)
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .previewLayout(.sizeThatFits)
    }

    static var sampleHealthVM: HealthViewModel = {
        let vm = HealthViewModel()
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        for i in 0..<14 {
            let d = cal.date(byAdding: .day, value: -i, to: today)!
            vm.stepVM.stepsPerDay[d] = i < 7 ? 5000 : 8000
        }
        return vm
    }()
}
