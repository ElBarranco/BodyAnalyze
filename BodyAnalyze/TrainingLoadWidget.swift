import SwiftUI

struct TrainingLoadArcView: View {
    var epoc: Double
    var maxEpoc: Double = 500.0 // adapté pour que 290 soit environ 60% rempli

    var body: some View {
        let percent = min(epoc / maxEpoc, 1.0)
        let angle = Angle(degrees: percent * 180)
        let color = colorForEPOC(epoc)

        VStack(spacing: 12) {
            ZStack {
                // Arc fond
                GaugeArcShape(percent: 1.0)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 16)

                // Arc valeur
                GaugeArcShape(percent: percent)
                    .stroke(color, style: StrokeStyle(lineWidth: 16, lineCap: .round))

                // Curseur bien positionné
                GeometryReader { geo in
                    Circle()
                        .fill(color)
                        .frame(width: 14, height: 14)
                        .position(x: geo.size.width / 2 + gaugeRadius * cos(angle.radians - .pi),
                                  y: geo.size.height + gaugeOffsetY(percent: percent, height: geo.size.height))
                }

                // Valeur au centre
                Text("\(Int(epoc))")
                    .font(.title2)
                    .bold()
                    .offset(y: 60)
            }
            .frame(width: 200, height: 120)

            // Légende
            HStack(spacing: 16) {
                ZoneLabel(color: .green, text: "Faible")
                ZoneLabel(color: .yellow, text: "Modérée")
                ZoneLabel(color: .red, text: "Élevée")
            }
            .font(.caption)
        }
        .padding()
    }

    // Rayon constant
    private var gaugeRadius: CGFloat {
        return 85
    }

    // Correction verticale du curseur
    private func gaugeOffsetY(percent: Double, height: CGFloat) -> CGFloat {
        // On veut que le curseur suive le demi-cercle, pas le fond
        return -gaugeRadius * sin(Angle(degrees: percent * 180).radians)
    }

    // Couleur dynamique
    private func colorForEPOC(_ epoc: Double) -> Color {
        switch epoc {
        case ..<200:
            return .green
        case 200..<400:
            return .yellow
        default:
            return .red
        }
    }
}

// 🔄 Arc de gauge
struct GaugeArcShape: Shape {
    var percent: Double = 1.0

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let radius = rect.width / 2
        let center = CGPoint(x: rect.midX, y: rect.maxY)
        let startAngle = Angle.degrees(180)
        let endAngle = Angle.degrees(180 + 180 * percent)

        path.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)

        return path
    }
}

// 🔘 Label zone
struct ZoneLabel: View {
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
