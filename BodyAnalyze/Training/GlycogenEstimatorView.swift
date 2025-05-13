//
//  GlycogenEstimatorView.swift
//  BodyAnalyze
//
//  Created by Lionel Barranco on 08/05/2025.
//


import SwiftUI

struct GlycogenEstimatorView: View {
    @StateObject private var viewModel = GlycogenEstimationViewModel()

    var body: some View {
        Form {
            Section(header: Text("Paramètres")) {
                Picker("Intensité", selection: $viewModel.intensity) {
                    ForEach(["Z1", "Z2", "Z3", "Z4", "Z5"], id: \.self) {
                        Text($0)
                    }
                }

                Stepper("Durée : \(viewModel.duration, specifier: "%.1f") h", value: $viewModel.duration, in: 0.5...10, step: 0.5)
                Stepper("Altitude : \(Int(viewModel.altitude)) m", value: $viewModel.altitude, in: 0...5000, step: 100)
                Stepper("Température : \(Int(viewModel.temperature)) °C", value: $viewModel.temperature, in: -20...40, step: 1)
                Toggle("Rechargé avant ?", isOn: $viewModel.preLoaded)
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
            }
        }
        .navigationTitle("Simulation Glycogène")
        .onAppear {
            viewModel.loadHealthDataIfNeeded()
        }
    }
}