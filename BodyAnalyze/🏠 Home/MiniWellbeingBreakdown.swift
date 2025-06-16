import SwiftUI

struct MiniWellbeingBreakdown: View {
    let hrvScore: Double   // /10
    let rhrScore: Double   // /10
    let activityScore: Double // /10

    var body: some View {
        HStack(spacing: 32) {
            verticalBar(title: "VFC", value: hrvScore, color: .blue)
            verticalBar(title: "BPM", value: rhrScore, color: .red)
            verticalBar(title: "Act.", value: activityScore, color: .green)
        }
        .padding(.top, 8)
    }

    private func verticalBar(title: String, value: Double, color: Color) -> some View {
        VStack(spacing: 6) {
            ZStack(alignment: .bottom) {
                Capsule()
                    .frame(width: 20, height: 100)
                    .foregroundColor(Color.gray.opacity(0.2))

                Capsule()
                    .frame(width: 20, height: CGFloat(value / 10.0 * 100))
                    .foregroundColor(color)
            }
            .animation(.easeInOut, value: value)

            Text(title)
                .font(.caption)
        }
    }
}
