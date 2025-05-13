import SwiftUI

struct HomeView: View {
    @EnvironmentObject var healthVM: HealthViewModel

    var body: some View {
        NavigationWrapperView(title: "Accueil 🏠") {
            VStack(spacing: 16) {
                // 🏠 Dashboard principal
                WeeklyExerciseView()
                    .environmentObject(healthVM)

                Text("🏠 Tableau de bord à venir...")
                    .padding(.top, 100)
                Spacer()
            }
            .padding()
        }
    }
}
