import SwiftUI

struct GlycogenEstimatorView: View {
    @StateObject private var viewModel = GlycogenEstimationViewModel()
    @State private var selectedIndex: Int? = nil

    var body: some View {
        Form {
            Section(header: Text("Paramètres")) {
                Picker("Activité", selection: $viewModel.activityType) {
                    ForEach(ActivityType.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                
                VStack(alignment: .leading) {
                    Text("Distance : \(viewModel.distance, specifier: "%.1f") km")
                    Slider(value: $viewModel.distance, in: 0...100, step: 1)
                }

                Picker("Intensité", selection: $viewModel.intensity) {
                    ForEach(["Z1", "Z2", "Z3", "Z4", "Z5"], id: \.self) {
                        Text($0)
                    }
                }

                VStack(alignment: .leading) {
                    Text("Durée : \(viewModel.duration, specifier: "%.1f") h")
                    Slider(value: $viewModel.duration, in: 0.5...12, step: 0.5)
                }

                VStack(alignment: .leading) {
                    Text("Altitude : \(Int(viewModel.altitude)) m")
                    Slider(value: $viewModel.altitude, in: 0...6000, step: 100)
                }

                VStack(alignment: .leading) {
                    Text("Température : \(Int(viewModel.temperature)) °C")
                    Slider(value: $viewModel.temperature, in: -20...40, step: 1)
                }

                VStack(alignment: .leading) {
                    Text("Dénivelé positif : \(Int(viewModel.elevationGain)) m")
                    Slider(value: $viewModel.elevationGain, in: 0...3000, step: 100)
                }

                Picker("Recharge glucidique", selection: $viewModel.glycogenLoad) {
                    ForEach(GlycogenLoadLevel.allCases) { level in
                        Text(level.rawValue).tag(level)
                    }
                }

                Toggle("Mange pendant ?", isOn: $viewModel.eatingDuring)
                if viewModel.eatingDuring {
                    VStack(alignment: .leading) {
                        Text("Glucides/h : \(Int(viewModel.carbsPerHour)) g")
                        Slider(value: $viewModel.carbsPerHour, in: 10...90, step: 5)
                    }
                }
            }

            Button("Estimer") {
                viewModel.estimate()
                selectedIndex = nil
            }

            if let result = viewModel.result {
                Section(header: Text("Courbe de glycogène")) {
                    GlycogenChartView(
                        result: result,
                        duration: viewModel.duration,
                        selectedIndex: $selectedIndex
                    )

                    if let i = selectedIndex {
                        let percent = result.timeSeries[i] / result.reserveMax * 100
                        let time = Double(i) / 100 * viewModel.duration
                        Text("📍 Glycogène à \(time.asHourMinuteString()) : \(Int(percent)) %")
                            .font(.caption)
                            .padding(.top, 4)
                    }

                    let (half, critical) = viewModel.thresholdCrossingTimes()
                    if half != nil || critical != nil {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("🔍 Analyse :")
                                .font(.headline)
                            if let h = half {
                                Text("⏳ Vous passez sous les **50%** à **\(h.asHourMinuteString())**")
                            }
                            if let c = critical {
                                Text("⚠️ Vous passez sous les **30%** à **\(c.asHourMinuteString())**")
                                    .foregroundColor(.red)
                            }
                        }
                        .padding(.top, 8)
                    }

                    Section(header: Text("Résultat")) {
                        Text("Réserve max : \(Int(result.reserveMax)) g")
                        Text("Utilisé : \(Int(result.glycogenUsed)) g")
                        Text("Restant : \(Int(result.remaining)) g")
                        Text("Reste : \(result.percentageRemaining, specifier: "%.1f") %")
                    }
                }
            }
        }
        .navigationTitle("Simulation Glycogène")
        .onAppear { viewModel.loadHealthDataIfNeeded() }
    }
}
