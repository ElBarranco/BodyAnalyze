//
//  EpocWeekChartView.swift
//  BodyAnalyze
//
//  Created by Lionel Barranco on 07/05/2025.
//


import SwiftUI
import Charts

struct EpocWeekChartView: View {
    @EnvironmentObject var healthVM: HealthViewModel
    let offset: Int

    private var calendar: Calendar { Calendar.current }

    private var days: [Date] {
        let today = calendar.startOfDay(for: Date())
        let weekday = calendar.component(.weekday, from: today)
        let daysFromMonday = (weekday + 5) % 7

        guard let thisMonday = calendar.date(byAdding: .day, value: -daysFromMonday, to: today),
              let startOfWeek = calendar.date(byAdding: .weekOfYear, value: offset, to: thisMonday)
        else { return [] }

        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: startOfWeek) }
    }

    var body: some View {
        let epocData = healthVM.trainingVM.epocPerDay

        VStack(alignment: .leading) {
            Chart {
                ForEach(days, id: \.self) { date in
                    let epoc = epocData[calendar.startOfDay(for: date)] ?? 0
                    BarMark(
                        x: .value("Jour", shortDayString(from: date)),
                        y: .value("EPOC", epoc)
                    )
                    .foregroundStyle(colorForEpoc(epoc))
                    .annotation {
                        if epoc > 0 {
                            Text("\(Int(epoc))")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            .frame(height: 200)

            // Légende couleurs
            HStack(spacing: 12) {
                LegendDot(color: .green, text: "Bas")
                LegendDot(color: .yellow, text: "Modéré")
                LegendDot(color: .red, text: "Élevé")
            }
            .font(.caption)
            .padding(.top, 4)
        }
        .padding(.horizontal)
    }

    private func shortDayString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }

    private func colorForEpoc(_ epoc: Double) -> Color {
        switch epoc {
        case ..<30: return .green
        case 30..<60: return .yellow
        default: return .red
        }
    }
}

// Légende : pastilles de couleur
struct LegendDot: View {
    var color: Color
    var text: String

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            Text(text)
        }
    }
}
