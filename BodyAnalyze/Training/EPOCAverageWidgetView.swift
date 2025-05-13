import SwiftUI

struct EPOCAverageWidgetView: View {
    var averageEPOC: Double

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("EPOC moyen")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                Button(action: {
                    // Action future pour ℹ️
                }) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.gray)
                }
            }

            Spacer()

            Text("\(Int(averageEPOC))")
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(.primary)

            Spacer()
        }
        // ❌ Ne pas mettre de frame fixe, padding, background ou shadow ici
    }
}

#Preview {
    // 🧪 Pour le preview, tu peux simuler le style du Tile
    EPOCAverageWidgetView(averageEPOC: 340)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 4)
        .previewLayout(.sizeThatFits)
}
