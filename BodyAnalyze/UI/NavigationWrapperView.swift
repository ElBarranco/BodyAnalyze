//
//  NavigationWrapperView.swift
//  BodyAnalyze
//
//  Created by Lionel Barranco on 05/05/2025.
//


import SwiftUI

struct NavigationWrapperView<Content: View>: View {
    @EnvironmentObject var healthVM: HealthViewModel
    @State private var showingSettings = false

    let title: String
    let content: () -> Content

    var body: some View {
        NavigationView {
            content()
                .navigationTitle(title)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            healthVM.loadAllData()
                        }) {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            showingSettings = true
                        }) {
                            Image(systemName: "gearshape.fill")
                        }
                    }
                }
                .sheet(isPresented: $showingSettings) {
                    SettingsView()
                        .environmentObject(healthVM)
                }
        }
    }
}