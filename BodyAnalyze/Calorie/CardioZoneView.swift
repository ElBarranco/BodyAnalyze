import SwiftUI

struct CardioZoneView: View {
    @EnvironmentObject var healthVM: HealthViewModel
    @AppStorage("showZone1") private var showZone1: Bool = false
    @State private var showGoalEditor: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 📅 Sélecteur de période
            HStack {
                Button("Semaine") {
                    healthVM.currentRange = .week
                }
                .buttonStyle(.borderedProminent)

                Button("Mois") {
                    healthVM.currentRange = .month
                }
                .buttonStyle(.borderedProminent)
            }

            // 📊 Nombre d'entraînements
            Text("📈 \(healthVM.trainingVM.workoutCount) entraînements analysés")
                .font(.headline)

            // 🔄 Affichage des zones
            let zonesToShow = (showZone1 ? [1] : []) + [2, 3, 4, 5]
            let durations = healthVM.heartVM.zoneDurations

            if durations.isEmpty {
                Text("Chargement des zones cardio…")
                    .foregroundColor(.gray)
            } else {
                let total = zonesToShow.reduce(0) { acc, zone in
                    acc + (durations[zone] ?? 0)
                }

                ForEach(zonesToShow, id: \.self) { zone in
                    let duration = durations[zone] ?? 0
                    let percent  = total > 0 ? duration / total * 100 : 0
                    let target   = healthVM.heartVM.cardioGoals[zone] ?? 0

                    VStack(alignment: .leading, spacing: 4) {
                        Text(
                            String(
                                format: "🧩 Zone %d: %.1f min – %.1f%%",
                                zone,
                                duration / 60,
                                percent
                            )
                        )
                        ZStack(alignment: .leading) {
                            ProgressView(value: percent, total: 100)
                                .tint(colorForZone(zone))
                                .frame(height: 8)

                            GeometryReader { geo in
                                let pos = geo.size.width * CGFloat(target / 100)
                                VStack(spacing: 2) {
                                    Rectangle()
                                        .frame(width: 2, height: 20)
                                        .foregroundColor(.gray)
                                    Text("🎯")
                                        .font(.caption2)
                                }
                                .position(x: pos, y: 10)
                            }
                        }
                        .frame(height: 20)
                    }
                }
            }

            // Bouton d’édition
            HStack {
                Spacer()
                Button {
                    showGoalEditor = true
                } label: {
                    Label("Objectifs", systemImage: "pencil")
                        .labelStyle(.titleAndIcon)
                }
                .buttonStyle(.bordered)
            }
        }
        .sheet(isPresented: $showGoalEditor) {
            CardioGoalEditorView(goals: $healthVM.heartVM.cardioGoals)
        }
        .onAppear {
            healthVM.loadAllData()
        }
    }

    private func colorForZone(_ zone: Int) -> Color {
        switch zone {
        case 1: return .gray
        case 2: return .green
        case 3: return .blue
        case 4: return .orange
        case 5: return .red
        default: return .black
        }
    }
}
