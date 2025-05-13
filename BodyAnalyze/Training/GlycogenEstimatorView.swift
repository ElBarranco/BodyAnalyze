import SwiftUI
import Charts

struct GlycogenEstimatorView: View {
    @StateObject private var viewModel = GlycogenEstimationViewModel()

    var body: some View {
        Form {
            Section(header: Text("Paramètres")) {
                Picker("Activité", selection: $viewModel.activityType) {
                    ForEach(ActivityType.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                Picker("Intensité", selection: $viewModel.intensity) {
                    ForEach(["Z1", "Z2", "Z3", "Z4", "Z5"], id: \.self) { Text($0) }
                }

                Stepper("Durée : \(viewModel.duration, specifier: "%.1f") h", value: $viewModel.duration, in: 0.5...12, step: 0.5)
                Stepper("Altitude : \(Int(viewModel.altitude)) m", value: $viewModel.altitude, in: 0...6000, step: 100)
                Stepper("Température : \(Int(viewModel.temperature)) °C", value: $viewModel.temperature, in: -20...40, step: 1)

                Picker("Recharge glucidique", selection: $viewModel.glycogenLoad) {
                    ForEach(GlycogenLoadLevel.allCases) { level in
                        Text(level.rawValue).tag(level)
                    }
                }

                Toggle("Mange pendant ?", isOn: $viewModel.eatingDuring)
                if viewModel.eatingDuring {
                    Stepper("Glucides/h : \(Int(viewModel.carbsPerHour)) g", value: $viewModel.carbsPerHour, in: 10...90, step: 5)
                }
            }

            Button("Estimer") {
                viewModel.estimate()
            }

            if let result = viewModel.result {
                Section(header: Text("Résultat")) {
                    Text("Réserve max : \(Int(result.reserveMax)) g")
                    Text("Utilisé : \(Int(result.glycogenUsed)) g")
                    Text("Restant : \(Int(result.remaining)) g")
                    Text("Reste : \(result.percentageRemaining, specifier: "%.1f") %")
                }

                Section(header: Text("Courbe de glycogène")) {
                    Chart {
                        ForEach(Array(result.timeSeries.enumerated()), id: \.offset) { index, value in
                            LineMark(
                                x: .value("h", Double(index) / 100.0 * viewModel.duration),
                                y: .value("g", value)
                            )
                        }
                        RuleMark(y: .value("Seuil de fatigue", result.reserveMax * 0.5))
                            .foregroundStyle(.orange)
                        RuleMark(y: .value("Zone critique", result.reserveMax * 0.3))
                            .foregroundStyle(.red)
                    }
                    .frame(height: 200)
                }
            }
        }
        .navigationTitle("Simulation Glycogène")
        .onAppear { viewModel.loadHealthDataIfNeeded() }
    }
}
