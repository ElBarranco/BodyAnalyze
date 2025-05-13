import SwiftUI

struct GroundContactWidget: View {
    let averageGCT: Double

    var body: some View {
        VStack(spacing: 8) {
            Text("Temps d'appui")
                .font(.caption)
                .foregroundColor(.secondary)

            Text("\(Int(averageGCT)) ms")
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
        switch averageGCT {
        case ..<220:
            return "Foulée très dynamique"
        case ..<250:
            return "Foulée efficace"
        case ..<280:
            return "Foulée stable"
        default:
            return "Foulée lourde"
        }
    }
}
