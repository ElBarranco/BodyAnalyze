//
//  StepGoalCalendarView.swift
//  BodyAnalyze
//
//  Created by Lionel Barranco on 05/05/2025.
//

import SwiftUI

struct StepGoalCalendarView: View {
    @EnvironmentObject var healthVM: HealthViewModel
    @State private var displayedMonth: Date = Calendar.current.date(
        from: Calendar.current.dateComponents([.year, .month], from: Date())
    )!

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

    var body: some View {
        VStack {
            // Month navigation
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

            // Weekday headers
            let symbols = calendar.veryShortWeekdaySymbols // ["L","M","M","J","V","S","D"]
            HStack {
                ForEach(0..<7) { i in
                    Text(symbols[(i + calendar.firstWeekday - 1) % 7])
                        .frame(maxWidth: .infinity)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }

            // Days grid
            let daysInMonth = calendar.range(of: .day, in: .month, for: monthStart)!
            let firstWeekday = calendar.component(.weekday, from: monthStart)
            let prefixCount = (firstWeekday - calendar.firstWeekday + 7) % 7
            let columns = Array(repeating: GridItem(.flexible()), count: 7)

            LazyVGrid(columns: columns, spacing: 12) {
                // Empty leading cells
                ForEach(0..<prefixCount, id: \.self) { _ in
                    Color.clear.frame(height: 40)
                }

                // Day cells
                ForEach(daysInMonth, id: \.self) { day in
                    let date = calendar.date(byAdding: .day, value: day - 1, to: monthStart)!
                    let isFuture = date > today
                    let ratio = stepRatio(for: date)

                    ZStack {
                        if !isFuture {
                            let fillColor: Color = ratio < 0.7 ? Color.gray.opacity(0.4) : color(for: date)
                            RoundedRectangle(cornerRadius: 6)
                                .fill(fillColor)
                                .frame(width: 36, height: 36)
                        }

                        Text("\(day)")
                            .font(.caption)
                            .bold()
                            .foregroundColor(isFuture ? Color.gray.opacity(0.8) : .white)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }

    private var isThisMonth: Bool {
        calendar.isDate(displayedMonth, equalTo: today, toGranularity: .month)
    }

    private func changeMonth(by delta: Int) {
        if let d = calendar.date(byAdding: .month, value: delta, to: displayedMonth) {
            displayedMonth = d
        }
    }

    private func stepRatio(for date: Date) -> Double {
        guard let goal = healthVM.stepVM.dailyStepGoal else { return 0 }
        let steps = healthVM.stepVM.stepsPerDay[calendar.startOfDay(for: date)] ?? 0
        return Double(steps) / Double(goal)
    }

    private func color(for date: Date) -> Color {
        guard date <= today, let goal = healthVM.stepVM.dailyStepGoal else {
            return .black
        }
        let steps = healthVM.stepVM.stepsPerDay[calendar.startOfDay(for: date)] ?? 0
        let ratio = Double(steps) / Double(goal)

        switch ratio {
        case ..<0.70:
            return .red
        case 0.70..<1.0:
            return Color.green.opacity(0.5)
        case 1.0..<1.25:
            return Color.green.opacity(0.75)
        default:
            return Color.green.opacity(1.0)
        }
    }
}

#Preview {
    StepGoalCalendarView()
        .environmentObject(HealthViewModel())
}
