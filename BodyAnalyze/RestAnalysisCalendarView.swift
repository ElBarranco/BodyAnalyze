// MonthlyRestAnalysisView.swift

import SwiftUI

// MARK: - Type et Vue réutilisables

enum TrainingType: Hashable {
    case heavy, light, rest

    var color: Color {
        switch self {
        case .heavy: return .red
        case .light: return .blue
        case .rest:  return .green
        }
    }

    var label: String {
        switch self {
        case .heavy: return "Entraînement intense"
        case .light: return "Entraînement léger"
        case .rest:  return "Jour de repos"
        }
    }
}

struct DayView: View {
    let day: Int?
    let trainingType: TrainingType?
    let isToday: Bool
    let isFuture: Bool

    var body: some View {
        ZStack {
            if let d = day, let type = trainingType {
                Circle()
                    .fill(isFuture ? Color.clear : type.color)
                    .frame(width: 36, height: 36)

                Text("\(d)")
                    .foregroundColor(isFuture ? .gray.opacity(0.4) : .white)
                    .bold()
                    .padding(6)
                    .background(
                        Circle()
                            .strokeBorder(
                                Color.white,
                                lineWidth: (isToday && !isFuture) ? 3 : 0
                            )
                    )
            } else {
                Circle()
                    .fill(Color.clear)
                    .frame(width: 36, height: 36)
            }
        }
        .frame(width: 50, height: 50)
    }
}

// MARK: - Vue principale

struct MonthlyRestAnalysisView: View {
    @EnvironmentObject var healthVM: HealthViewModel
    @State private var displayedMonth: Date = Calendar.current.date(
        from: Calendar.current.dateComponents([.year, .month], from: Date())
    )!

    private let calendar = Calendar.current
    private var today: Date { calendar.startOfDay(for: Date()) }

    var body: some View {
        VStack {
            // 🗓️ Mois + navigation
            HStack {
                Button(action: { changeMonth(by: -1) }) {
                    Image(systemName: "chevron.left")
                }
                Spacer()
                Text("Repos Analyse – \(monthName(from: displayedMonth))")
                    .font(.title2)
                Spacer()
                Button(action: { changeMonth(by: 1) }) {
                    Image(systemName: "chevron.right")
                }
            }
            .padding(.top)

            // 📆 Jours de la semaine
            let weekDays = ["L", "M", "M", "J", "V", "S", "D"]
            HStack {
                ForEach(0..<weekDays.count, id: \.self) { i in
                    Text(weekDays[i])
                        .frame(width: 50)
                        .foregroundColor(.gray)
                        .font(.caption)
                }
            }

            // 📅 Grille du mois
            let range = calendar.range(of: .day, in: .month, for: displayedMonth)!
            let numDays = range.count
            let firstWeekdayIndex = weekdayOffset(for: displayedMonth)
            let columns = Array(repeating: GridItem(.flexible()), count: 7)

            LazyVGrid(columns: columns, spacing: 12) {
                // cases vides avant le 1er jour
                ForEach(0..<firstWeekdayIndex, id: \.self) { _ in
                    DayView(day: nil, trainingType: nil, isToday: false, isFuture: false)
                }
                // jours du mois
                ForEach(1...numDays, id: \.self) { day in
                    let date = calendar.date(
                        byAdding: .day, value: day - 1, to: displayedMonth
                    )!
                    let isToday = calendar.isDate(today, inSameDayAs: date)
                    let isFuture = date > today
                    let type = healthVM.trainingVM.trainingTypesByDay[
                        calendar.startOfDay(for: date)
                    ] ?? .rest

                    DayView(
                        day: day,
                        trainingType: type,
                        isToday: isToday,
                        isFuture: isFuture
                    )
                }
            }
            .padding()

            // 🔶 LÉGENDE
            HStack(spacing: 16) {
                ForEach([TrainingType.heavy, .light, .rest], id: \.self) { type in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(type.color)
                            .frame(width: 12, height: 12)
                        Text(type.label)
                            .font(.caption)
                    }
                }
            }
            .padding(.top, 8)

            // 📊 STAT
            Text("Nombre de jours de repos : \(restDayCount(for: displayedMonth))")
                .font(.footnote)
                .foregroundColor(.secondary)
                .padding(.top, 4)
        }
        .onAppear {
            healthVM.loadAllData()
        }
    }

    // MARK: - Méthodes utilitaires

    private func changeMonth(by value: Int) {
        if let newDate = calendar.date(
            byAdding: .month, value: value, to: displayedMonth
        ) {
            displayedMonth = newDate
        }
    }

    private func restDayCount(for month: Date) -> Int {
        let range = calendar.range(of: .day, in: .month, for: month)!
        return range
            .compactMap {
                calendar.date(byAdding: .day, value: $0 - 1, to: month)
            }
            .filter {
                healthVM.trainingVM.trainingTypesByDay[
                    calendar.startOfDay(for: $0)
                ] == .rest
            }
            .count
    }

    private func monthName(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: date).capitalized
    }

    private func weekdayOffset(for date: Date) -> Int {
        let weekday = calendar.component(.weekday, from: date)
        return (weekday + 5) % 7
    }
}

#Preview {
    MonthlyRestAnalysisView()
        .environmentObject(HealthViewModel())
}
