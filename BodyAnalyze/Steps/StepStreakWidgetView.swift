//
//  StepStreakWidgetView.swift
//  BodyAnalyze
//
//  Created by Lionel Barranco on 07/05/2025.
//


import SwiftUI

struct StepStreakWidgetView: View {
    @EnvironmentObject var healthVM: HealthViewModel

    var body: some View {
        VStack {
            Image(systemName: "flame.fill")
                .font(.system(size: 36))
                .foregroundColor(.pink)

            Text("\(healthVM.stepVM.stepStreak) jours")
                .font(.title)
                .bold()
                .foregroundColor(.pink)

            Text("streak 👣")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.pink.opacity(0.1))
        .cornerRadius(12)
    }
}