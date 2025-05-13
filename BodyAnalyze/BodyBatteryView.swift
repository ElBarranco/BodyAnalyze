import SwiftUI

struct BodyBatteryView: View {
    @EnvironmentObject var healthVM: HealthViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("⚡️ Body Battery")
                .font(.headline)

            // Gauge circulaire
            ZStack {
                ArcShape()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 16)

                ArcShape(percent: batteryPercent())
                    .stroke(batteryColor(), style: StrokeStyle(lineWidth: 16, lineCap: .round))

                Text(String(format: "%.1f / 10", heartVM.bodyBatteryScore))
                    .font(.title2)
                    .bold()
            }
            .frame(width: UIScreen.main.bounds.width * 0.7, height: 120)
            .frame(maxWidth: .infinity)

            // 3 indicateurs de forme : VFC, FC repos, charge
            HStack(spacing: 12) {
                DailyFormBox(
                    title: "VFC",
                    value: heartVM.hrvValue,
                    status: interpretHRV(heartVM.hrvValue)
                )
                DailyFormBox(
                    title: "Repos",
                    value: heartVM.restingHR,
                    status: interpretRestingHR(heartVM.restingHR)
                )
                DailyFormBox(
                    title: "Charge",
                    value: trainingVM.trainingLoad7d,
                    status: interpretLoad(trainingVM.trainingLoad7d)
                )
            }
        }
        .padding(.top)
    }

    // MARK: - Shortcuts to sub-viewmodels
    private var heartVM: HeartMetricsViewModel { healthVM.heartVM }
    private var trainingVM: TrainingViewModel { healthVM.trainingVM }

    // MARK: - Helpers

    private func batteryPercent() -> Double {
        min(heartVM.bodyBatteryScore / 10.0, 1.0)
    }

    private func batteryColor() -> Color {
        switch heartVM.bodyBatteryScore {
        case 0..<3: return .red
        case 3..<7: return .orange
        default:    return .green
        }
    }

    private func interpretHRV(_ hrv: Double) -> DailyFormStatus {
        switch hrv {
        case ..<30: return .low
        case ..<60: return .medium
        default:    return .high
        }
    }

    private func interpretRestingHR(_ bpm: Double) -> DailyFormStatus {
        switch bpm {
        case ..<52: return .high
        case ..<65: return .medium
        default:    return .low
        }
    }

    private func interpretLoad(_ load: Double) -> DailyFormStatus {
        switch load {
        case ..<200: return .low
        case ..<500: return .medium
        default:     return .high
        }
    }
}

// ✅ Encadré individuel de sous-état
struct DailyFormBox: View {
    let title: String
    let value: Double
    let status: DailyFormStatus

    var body: some View {
        VStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray)
            Text(String(format: "%.0f", value))
                .font(.title3)
                .bold()
                .foregroundColor(status.color)
            Text(status.label)
                .font(.caption)
                .foregroundColor(status.color)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

enum DailyFormStatus {
    case low, medium, high

    var label: String {
        switch self {
        case .low:    return "⚠️ Bas"
        case .medium: return "🟡 Moyen"
        case .high:   return "✅ Bon"
        }
    }

    var color: Color {
        switch self {
        case .low:    return .red
        case .medium: return .orange
        case .high:   return .green
        }
    }
}

// ✅ Forme en arc semi-horizontal
struct ArcShape: Shape {
    var percent: Double = 1.0

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let radius = rect.width / 2
        let startAngle = Angle.degrees(180)
        let endAngle = Angle.degrees(180 + (percent * 180))

        path.addArc(center: CGPoint(x: rect.midX, y: rect.maxY),
                    radius: radius,
                    startAngle: startAngle,
                    endAngle: endAngle,
                    clockwise: false)

        return path
    }
}

#Preview {
    BodyBatteryView()
        .environmentObject(HealthViewModel())
}
