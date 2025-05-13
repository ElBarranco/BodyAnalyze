import SwiftUI

struct StrideLengthWidget: View {
    let averageStride: Double

    var body: some View {
        VStack(spacing: 8) {
            Text("Longueur de foulée")
                .font(.caption)
                .foregroundColor(.secondary)

            Text("\(String(format: "%.2f", averageStride)) m")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.primary)

            Text(feedback)
                .font(.caption2)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, minHeight: 100)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }

    private var feedback: String {
        switch averageStride {
        case ..<0.9:
            return "Foulée courte — cadence élevée ?"
        case ..<1.2:
            return "Foulée normale"
        default:
            return "Foulée longue — efficace !"
        }
    }
}
