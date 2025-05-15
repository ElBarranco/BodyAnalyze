//
//  LightExposureChartView.swift
//  BodyAnalyze
//
//  Created by Lionel Barranco on 14/05/2025.
//

import SwiftUI
import Charts

struct LightExposureChartView: View {
    @ObservedObject var viewModel: StepCountViewModel
    let numberOfDays: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Exposition à la lumière naturelle 🌞")
                .font(.headline)

            if sortedExposureData.isEmpty {
                Text("Aucune donnée disponible")
                    .foregroundColor(.secondary)
                    .padding(.top, 40)
            } else {
                Chart {
                    ForEach(sortedExposureData.suffix(numberOfDays), id: \.key) { date, value in
                        BarMark(
                            x: .value("Jour", formattedDate(date)),
                            y: .value("Minutes", value)
                        )
                        .foregroundStyle(color(for: value))
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .frame(height: 180)
                .padding(.top, 8)

                Text("⏱️ Moyenne : \(Int(viewModel.averageLightExposure)) min/jour")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text(viewModel.lightExposureStatus)
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }
        }
        .padding()
    }

    private var sortedExposureData: [(key: Date, value: Double)] {
        viewModel.lightExposurePerDay
            .sorted { $0.key < $1.key }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "E d MMM"
        return formatter.string(from: date)
    }

    private func color(for value: Double) -> Color {
        switch value {
        case ..<10: return .red
        case 10..<30: return .orange
        default: return .green
        }
    }
}

#Preview {
    LightExposureChartView(viewModel: mockViewModel, numberOfDays: 7)
}

private var mockViewModel: StepCountViewModel {
    let vm = StepCountViewModel()
    let calendar = Calendar.current

    for i in 0..<14 {
        let date = calendar.date(byAdding: .day, value: -i, to: Date())!
        let minutes = Double.random(in: 0...60)
        vm.lightExposurePerDay[calendar.startOfDay(for: date)] = minutes
    }

    let total = vm.lightExposurePerDay.values.reduce(0, +)
    vm.averageLightExposure = total / Double(vm.lightExposurePerDay.count)

    return vm
}
