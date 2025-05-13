import SwiftUI
import Charts

struct StepHistogramView: View {
    @EnvironmentObject var healthVM: HealthViewModel
    @State private var selectedDay: Date?

    /// Les 7 derniers jours, du plus ancien au plus récent
    private var days: [Date] {
        let cal   = Calendar.current
        let today = cal.startOfDay(for: Date())
        return (0..<7)
            .compactMap { cal.date(byAdding: .day, value: -$0, to: today) }
            .sorted()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("🚶‍♂️ Pas – 7 derniers jours")
                .font(.headline)
                .padding(.leading)

            GeometryReader { geo in
                ZStack {
                    Chart {
                        ForEach(days, id: \.self) { day in
                            let total   = healthVM.stepVM.stepsPerDay[day] ?? 0
                            let running = healthVM.stepVM.runningStepsPerDay[day] ?? 0
                            let walking = max(total - running, 0)
                            let label   = shortDayString(from: day)

                            // barre marche
                            BarMark(
                                x: .value("Jour", label),
                                y: .value("Walking", walking)
                            )
                            .foregroundStyle(.blue)

                            // barre sport
                            BarMark(
                                x: .value("Jour", label),
                                y: .value("Sport", running)
                            )
                            .foregroundStyle(.green)

                            // annotation ✅ si objectif atteint
                            if let goal = healthVM.stepVM.dailyStepGoal,
                               total >= goal {
                                PointMark(
                                    x: .value("Jour", label),
                                    y: .value("Pas", total)
                                )
                                .annotation(position: .top) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.caption)
                                }
                            }
                        }
                    }
                    .chartXAxis {
                        AxisMarks(values: days.map { shortDayString(from: $0) }) { _ in
                            AxisGridLine(); AxisTick(); AxisValueLabel()
                        }
                    }
                    .frame(height: 200)

                    // annotation au tap
                    if let day = selectedDay {
                        let total = healthVM.stepVM.stepsPerDay[day] ?? 0
                        let idx   = days.firstIndex(of: day) ?? 0
                        let width = geo.size.width / CGFloat(days.count)
                        let xPos  = width * (CGFloat(idx) + 0.5)

                        Text("\(total) pas")
                            .font(.caption)
                            .padding(6)
                            .background(Color(.systemBackground).opacity(0.8))
                            .cornerRadius(6)
                            .position(x: xPos, y: 12)
                    }

                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                        .onTapGesture { loc in
                            let width = geo.size.width / CGFloat(days.count)
                            let idx = min(days.count - 1,
                                          max(0, Int(loc.x / width)))
                            selectedDay = days[idx]
                        }
                }
            }
            .frame(height: 200)

            HStack(spacing: 24) {
                HStack(spacing: 6) {
                    Rectangle().fill(Color.blue).frame(width: 12, height: 12)
                    Text("Walking").font(.caption)
                }
                HStack(spacing: 6) {
                    Rectangle().fill(Color.green).frame(width: 12, height: 12)
                    Text("Sport").font(.caption)
                }
                if healthVM.stepVM.dailyStepGoal != nil {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Objectif atteint").font(.caption)
                    }
                }
            }
            .padding(.leading)
            .font(.caption)
        }
        .padding()
    }

    private func shortDayString(from date: Date) -> String {
        let f = DateFormatter()
        f.locale     = Locale(identifier: "fr_FR")
        f.dateFormat = "E"
        return f.string(from: date).capitalized
    }
}
