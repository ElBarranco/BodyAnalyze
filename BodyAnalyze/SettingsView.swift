import SwiftUI

struct SettingsView: View {
    @AppStorage("showZone1") var showZone1: Bool = false
    @AppStorage("maxBPM")   var maxBPM: Double = 0  // on initialisera à 0, puis on surchargera

    var body: some View {
      NavigationView {
        Form {
          Toggle("Afficher la zone 1 (récup)", isOn: $showZone1)
          
          Section(header: Text("Fréquence cardiaque max")) {
            Stepper(value: $maxBPM, in: 100...220, step: 1) {
              Text("Max BPM : \(Int(maxBPM)) bpm")
            }
            .onAppear {
              // si jamais on n'a pas encore de valeur, on la calcule
              if maxBPM == 0 {
                SettingsViewModel.computeDefaultMaxBPM { defaultMax in
                  maxBPM = defaultMax
                }
              }
            }
          }
        }
        .navigationTitle("Réglages")
        .navigationBarTitleDisplayMode(.inline)
      }
    }
}
