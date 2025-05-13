import SwiftUI

struct FormeFatigueWidgetView: View {
    @EnvironmentObject var healthVM: HealthViewModel
    var isSimulated: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("📈 Forme vs Fatigue")
                .font(.title2)
                .bold()

            GeometryReader { geo in
                ZStack {
                    let days = getLast7Days()

                    // 🔴 Courbe Fatigue (ATL)
                    Path { path in
                        for (index, day) in days.enumerated() {
                            let load = isSimulated
                                ? simulateLoad(for: day)
                                : healthVM.trainingVM.calculateATL(for: day)
                            let x = geo.size.width * CGFloat(index) / CGFloat(days.count - 1)
                            let y = geo.size.height * (1 - CGFloat(min(load, 100)) / 100)
                            if index == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                    }
                    .stroke(Color.red, lineWidth: 2)

                    // 🔵 Courbe Forme (CTL)
                    Path { path in
                        for (index, day) in days.enumerated() {
                            let load = isSimulated
                                ? simulateLoad(for: day)
                                : healthVM.trainingVM.calculateCTL(for: day)
                            let x = geo.size.width * CGFloat(index) / CGFloat(days.count - 1)
                            let y = geo.size.height * (1 - CGFloat(min(load, 100)) / 100)
                            if index == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                    }
                    .stroke(Color.blue, lineWidth: 2)
                }
            }
            .frame(height: 200)

            HStack {
                Circle().fill(Color.red).frame(width: 10, height: 10)
                Text("Fatigue (ATL)")
                Spacer()
                Circle().fill(Color.blue).frame(width: 10, height: 10)
                Text("Forme (CTL)")
            }
            .font(.caption)
            .padding(.top, 4)

            Text(todayStatus())
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.top)
        }
        .padding()
    }

    private func getLast7Days() -> [Date] {
        let calendar = Calendar.current
        return (0..<7)
            .compactMap { calendar.date(byAdding: .day, value: -$0, to: Date()) }
            .reversed()
    }

    private func todayStatus() -> String {
        let today = Calendar.current.startOfDay(for: Date())
        let atl = isSimulated ? simulateLoad(for: today) : healthVM.trainingVM.calculateATL(for: today)
        let ctl = isSimulated ? simulateLoad(for: today) : healthVM.trainingVM.calculateCTL(for: today)
        let tsb = ctl - atl

        if tsb > 10 {
            return "✅ Bonne récupération, prêt à performer !"
        } else if tsb < -10 {
            return "⚠️ Fatigue importante, attention au surmenage."
        } else {
            return "🟡 Charge équilibrée, entraînement optimal."
        }
    }

    private func simulateLoad(for date: Date) -> Double {
        let dayOffset = Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0
        return 50 + 30 * sin(Double(dayOffset) / 2.0)
    }
}
