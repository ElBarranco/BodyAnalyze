//
//  HomeView.swift
//  BodyAnalyze
//
//  Created by Lionel Barranco on 05/05/2025.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var healthVM: HealthViewModel

    var body: some View {
        NavigationWrapperView(title: "Accueil 🏠") {
            VStack {
                // 🏠 Dashboard principal à venir
                Text("🏠 Tableau de bord à venir...")
                    .padding(.top, 100)
                Spacer()
            }
        }
    }
}
