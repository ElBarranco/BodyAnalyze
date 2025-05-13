import SwiftUI

struct VerticalCaloriesChartView: View {
    let activeCalories: [Date: Double]
    let basalCalories: [Date: Double]

    enum BarType {
        case metabolism, active
    }

    @State private var selectedBar: (String, BarType)? = nil

    private var dayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "E"
        return formatter
    }

    var body: some View {
        let calendar = Calendar.current
        let today = Date()
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today))!
        let weekDays = (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: startOfWeek) }

        let data = weekDays.map { date -> (String, Date, Double, Double) in
            let key = calendar.startOfDay(for: date)
            let metabolism = basalCalories[key] ?? 0
            let active = activeCalories[key] ?? 0
            let label = dayFormatter.string(from: date)
            return (label, date, metabolism, active)
        }

        let completedDays = data.filter { (_, date, _, _) in
            date < calendar.startOfDay(for: today)
        }

        let totalSum = completedDays.map { $0.2 + $0.3 }.reduce(0, +)
        let average = completedDays.isEmpty ? 0 : totalSum / Double(completedDays.count)

        VStack(alignment: .center) {
            Text("🔥 Calories totales")
                .font(.headline)
                .padding(.bottom, 4)

            HStack(alignment: .bottom, spacing: 16) {
                ForEach(data, id: \.0) { dayLabel, _, metabolism, active in
                    VStack(spacing: 4) {
                        if let (selectedDay, type) = selectedBar, selectedDay == dayLabel {
                            let value = type == .metabolism ? metabolism : active
                            let label = type == .metabolism ? "Métabolisme" : "Activité"
                            Text("\(label) : \(Int(value)) kcal")
                                .font(.caption2)
                                .foregroundColor(type == .metabolism ? .green : .orange)
                        } else {
                            Text("\(Int(metabolism + active)) kcal")
                                .font(.caption2)
                                .foregroundColor(.primary)
                        }

                        ZStack(alignment: .bottom) {
                            VStack(spacing: 0) {
                                Rectangle()
                                    .fill(Color.orange)
                                    .frame(height: CGFloat(active / (data.map { $0.2 + $0.3 }.max() ?? 1)) * 150)
                                    .opacity(isSelected(day: dayLabel, type: .active) ? 1.0 : 0.7)
                                    .overlay(
                                        isSelected(day: dayLabel, type: .active) ?
                                        RoundedRectangle(cornerRadius: 4)
                                            .stroke(Color.orange.opacity(0.9), lineWidth: 2)
                                        : nil
                                    )
                                    .onTapGesture {
                                        toggleSelection(dayLabel, .active)
                                    }

                                Rectangle()
                                    .fill(Color.green)
                                    .frame(height: CGFloat(metabolism / (data.map { $0.2 + $0.3 }.max() ?? 1)) * 150)
                                    .opacity(isSelected(day: dayLabel, type: .metabolism) ? 1.0 : 0.7)
                                    .overlay(
                                        isSelected(day: dayLabel, type: .metabolism) ?
                                        RoundedRectangle(cornerRadius: 4)
                                            .stroke(Color.green.opacity(0.9), lineWidth: 2)
                                        : nil
                                    )
                                    .onTapGesture {
                                        toggleSelection(dayLabel, .metabolism)
                                    }
                            }
                        }
                        .frame(width: 20)
                        .cornerRadius(4)

                        Text(dayLabel.capitalized)
                            .font(.caption)
                    }
                }
            }
            .frame(maxWidth: .infinity, minHeight: 160)
            .padding(.top, 4)

            // 🧾 Nouvelle légende
            HStack(spacing: 16) {
                HStack {
                    Circle().fill(Color.green).frame(width: 10, height: 10)
                    Text("Métabolisme").font(.caption)
                }
                HStack {
                    Circle().fill(Color.orange).frame(width: 10, height: 10)
                    Text("Activité").font(.caption)
                }
            }
            .padding(.top, 8)

            if completedDays.isEmpty {
                Text("Aucune journée terminée pour le moment")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .padding(.top, 12)
            } else {
                Text("Moyenne sur \(completedDays.count) jours terminés : \(Int(average)) kcal")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .padding(.top, 12)
            }
        }

        // ❌ Supprimé :
        // .frame(maxWidth: .infinity)
        // .padding()
        // .background(...)
        // .cornerRadius(...)
        // .shadow(...)
    }

    private func toggleSelection(_ day: String, _ type: BarType) {
        if selectedBar?.0 == day && selectedBar?.1 == type {
            selectedBar = nil
        } else {
            selectedBar = (day, type)
        }
    }

    private func isSelected(day: String, type: BarType) -> Bool {
        return selectedBar?.0 == day && selectedBar?.1 == type
    }
}
