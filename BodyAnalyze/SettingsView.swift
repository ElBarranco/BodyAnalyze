import SwiftUI

struct SettingsView: View {
    @AppStorage("showZone1") var showZone1: Bool = false
    @AppStorage("maxBPM") var maxBPM: Double = 0
    
    @StateObject private var viewModel = SettingsViewModel()

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("🧍 Données personnelles")) {
                    HStack {
                        Text("Âge")
                        Spacer()
                        Text(viewModel.age != nil ? "\(viewModel.age!) ans" : "—")
                            .foregroundColor(.gray)
                    }
                    HStack {
                        Text("Taille")
                        Spacer()
                        Text(viewModel.height != nil ? String(format: "%.0f cm", viewModel.height!) : "—")
                            .foregroundColor(.gray)
                    }
                    HStack {
                        Text("Poids")
                        Spacer()
                        Text(viewModel.weight != nil ? String(format: "%.1f kg", viewModel.weight!) : "—")
                            .foregroundColor(.gray)
                    }

                    Label("Tu peux éditer ces infos dans l'app Santé", systemImage: "heart.fill")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }

                Toggle("Afficher la zone 1 (récup)", isOn: $showZone1)
                
                Section(header: Text("Fréquence cardiaque max")) {
                    Stepper(value: $maxBPM, in: 100...220, step: 1) {
                        Text("Max BPM : \(Int(maxBPM)) bpm")
                    }
                    .onAppear {
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
