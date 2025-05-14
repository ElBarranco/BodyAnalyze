import SwiftUI
import Charts

struct DisciplinePieChartView: View {
    var distribution: [WorkoutDiscipline: Int]
    @State private var selectedDiscipline: WorkoutDiscipline? = nil

    var total: Int {
        distribution.values.reduce(0, +)
    }

    var sortedDistribution: [(WorkoutDiscipline, Int)] {
        distribution.sorted { $0.value > $1.value }
    }

    var body: some View {
        VStack {
            Text("Répartition des activités 🏅 (30 jours)")
                .font(.headline)
                .padding(.bottom)

            ZStack {
                Chart {
                    ForEach(sortedDistribution, id: \.0) { (discipline, count) in
                        let percent = Double(count) / Double(total)
                        SectorMark(
                            angle: .value("Pourcentage", percent),
                            innerRadius: .ratio(0.5),
                            angularInset: 1.5
                        )
                        .foregroundStyle(by: .value("Discipline", discipline.rawValue))
                        .annotation(position: .overlay) {
                            Text(discipline.emoji)
                        }
                    }
                }
                .chartLegend(.hidden)
                .frame(height: 250)
                .chartOverlay { proxy in
                    GeometryReader { geometry in
                        Rectangle()
                            .fill(Color.clear)
                            .contentShape(Rectangle())
                            .onTapGesture { location in
                                let angle = angleFromCenter(location: location, in: geometry.size)
                                // Find corresponding slice
                                var startAngle: Double = 0.0
                                for (discipline, count) in sortedDistribution {
                                    let percent = Double(count) / Double(total)
                                    let endAngle = startAngle + percent * 360
                                    if angle >= startAngle && angle < endAngle {
                                        selectedDiscipline = discipline
                                        return
                                    }
                                    startAngle = endAngle
                                }
                                selectedDiscipline = nil
                            }
                    }
                }

                VStack {
                    if let selected = selectedDiscipline {
                        Text("\(selected.emoji) \(selected.rawValue.capitalized)")
                            .font(.title2)
                        if let count = distribution[selected] {
                            Text("\(count) entraînements")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    } else {
                        Text("Total: \(total) séances")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .padding()
    }

    // Helper: transforme un point en angle (0 = haut, tourne dans le sens horaire)
    private func angleFromCenter(location: CGPoint, in size: CGSize) -> Double {
        let dx = location.x - size.width / 2
        let dy = location.y - size.height / 2
        let radians = atan2(dy, dx)
        var degrees = radians * 180 / .pi
        degrees = (degrees < 0 ? 360 + degrees : degrees)
        return degrees
    }
}
