//
//  LightExposureCalendarView.swift
//  BodyAnalyze
//
//  Created by Lionel Barranco on 15/05/2025.
//

import SwiftUI

struct LightExposureCalendarView: View {
    @ObservedObject var viewModel: StepCountViewModel
    @State private var displayedMonth: Date

    private let calendar = Calendar.current
    private var today: Date { calendar.startOfDay(for: Date()) }
    private var monthStart: Date {
        calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth))!
    }

    private var monthNameFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "fr_FR")
        f.dateFormat = "LLLL yyyy"
        return f
    }()

    init(viewModel: StepCountViewModel) {
        self.viewModel = viewModel
        _displayedMonth = State(initialValue: Calendar.current.date(
            from: Calendar.current.dateComponents([.year, .month], from: Date())
        )!)
    }

    var body: some View {
        VStack {
            // Navigation mois
            HStack {
                Button(action: { changeMonth(by: -1) }) {
                    Image(systemName: "chevron.left")
                }
                Spacer()
                Text(monthNameFormatter.string(from: displayedMonth).capitalized)
                    .font(.title2)
                Spacer()
                Button(action: { changeMonth(by: 1) }) {
                    Image(systemName: "chevron.right")
                }
                .disabled(isThisMonth)
                .opacity(isThisMonth ? 0.5 : 1)
            }
            .padding(.horizontal)

            // En-têtes jours
            let symbols = calendar.veryShortWeekdaySymbols
            HStack {
                ForEach(0..<7) { i in
                    Text(symbols[(i + calendar.firstWeekday - 1) % 7])
                        .frame(maxWidth: .infinity)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }

            // Grille
            let daysInMonth = calendar.range(of: .day, in: .month, for: monthStart)!
            let firstWeekday = calendar.component(.weekday, from: monthStart)
            let prefixCount = (firstWeekday - calendar.firstWeekday + 7) % 7
            let columns = Array(repeating: GridItem(.flexible()), count: 7)

            LazyVGrid(columns: columns, spacing: 12) {
                // Cellules vides
                ForEach(0..<prefixCount, id: \.self) { _ in
                    Color.clear.frame(height: 40)
                }

                // Cellules jour
                ForEach(daysInMonth, id: \.self) { day in
                    let date = calendar.date(byAdding: .day, value: day - 1, to: monthStart)!
                    let isFuture = date > today
                    let minutes = viewModel.lightExposurePerDay[calendar.startOfDay(for: date)] ?? 0

                    ZStack {
                        if !isFuture {
                            let color = exposureColor(for: minutes)
                            RoundedRectangle(cornerRadius: 6)
                                .fill(color)
                                .frame(width: 36, height: 36)
                        }

                        Text("\(day)")
                            .font(.caption)
                            .bold()
                            .foregroundColor(isFuture ? Color.gray.opacity(0.6) : .white)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .onAppear {
            viewModel.loadLightExposureForMonth(displayedMonth: displayedMonth)
        }
        .onChange(of: displayedMonth) { newMonth in
            viewModel.loadLightExposureForMonth(displayedMonth: newMonth)
        }
    }

    private var isThisMonth: Bool {
        calendar.isDate(displayedMonth, equalTo: today, toGranularity: .month)
    }

    private func changeMonth(by delta: Int) {
        if let newDate = calendar.date(byAdding: .month, value: delta, to: displayedMonth) {
            displayedMonth = newDate
        }
    }

    private func exposureColor(for minutes: Double) -> Color {
        switch minutes {
        case ..<10:
            return .yellow.opacity(0.5)
        case 10..<30:
            return .yellow.opacity(0.75)
        case 30...:
            return .yellow.opacity(1.0)
        default:
            return .gray
        }
    }
}
