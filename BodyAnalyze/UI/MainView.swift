import SwiftUI

struct MainView: View {
    @EnvironmentObject var healthVM: HealthViewModel
    @State private var showingSettings = false

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("🔧 Paramètres et Batterie du corps")
                    .font(.headline)

                // 🆕 Body Battery (à garder ici si tu veux la mettre en valeur)
                BodyBatteryView()
                    .padding()

                Spacer()
            }
            .navigationTitle("Analyse")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { healthVM.loadAllData() } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingSettings = true } label: {
                        Image(systemName: "gearshape.fill")
                            .imageScale(.large)
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
                    .environmentObject(healthVM)
            }
        }
        .onAppear {
            healthVM.loadAllData()
        }
    }
}
