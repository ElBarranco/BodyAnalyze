import SwiftUI

@main
struct BodyAnalyzeApp: App {
    @StateObject var healthVM = HealthViewModel()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(healthVM) // 🔁 Toujours injecté dans toute la hiérarchie
        }
    }
}
