//
//  StepsView.swift
//  BodyAnalyze
//
//  Created by Lionel Barranco on 05/05/2025.
//

import SwiftUI

struct StepsView: View {
    @EnvironmentObject var healthVM: HealthViewModel
    @State private var showingGoalSheet = false

    var body: some View {
        NavigationWrapperView(title: "Pas 👣") {
            ScrollView {
                TileGrid {
                    Tile(span: .full) {
                        ObjectiveBannerView(showingGoalSheet: $showingGoalSheet)
                            .environmentObject(healthVM)
                    }.wrapped()
                }

                // 🔥 Ajout en dehors du TileGrid
                if healthVM.stepVM.hasDefinedGoal {
                    TileGrid {
                        Tile(span: .half) {
                            StepDailyProgressWidgetView()
                                .environmentObject(healthVM)
                        }.wrapped()

                        Tile(span: .half) {
                            StepStreakWidgetView()
                                .environmentObject(healthVM)
                        }.wrapped()
                    }
                }

                TileGrid {
                    Tile(span: .full) {
                        WalkingDistanceWidgetView()
                            .environmentObject(healthVM)
                    }.wrapped()

                    Tile(span: .full) {
                        StepGoalCalendarView()
                            .environmentObject(healthVM)
                    }.wrapped()

                    Tile(span: .full) {
                        StepHistogramView()
                            .environmentObject(healthVM)
                    }.wrapped()

                    Tile(span: .half) {
                        StepAverageWidgetView()
                            .environmentObject(healthVM)
                    }.wrapped()

                    Tile(span: .half) {
                        StepTrendWidgetView()
                            .environmentObject(healthVM)
                    }.wrapped()

                    Tile(span: .full) {
                        WeeklyStepsTrendView()
                            .environmentObject(healthVM)
                    }.wrapped()
                    
                    Tile(span: .full) {
                        LightExposureChartView(
                            viewModel: healthVM.stepVM,
                            numberOfDays: 7
                        )
                    }.wrapped()
                }
                .padding(.vertical)
            }
            .onAppear {
                print("🚀 Chargement distance marche/course")
                healthVM.stepVM.loadWalkingDistancePerWeek(range: .week)
                
                print("🌞 Chargement exposition lumière naturelle")
                healthVM.stepVM.loadLightExposureData(range: TimeRange.week) 
            }
            .sheet(isPresented: $showingGoalSheet) {
                GoalInputView(goal: $healthVM.stepVM.dailyStepGoal)
            }
        }
    }
}

// Ce petit banner pour la saisie / modification de l'objectif
struct ObjectiveBannerView: View {
    @EnvironmentObject var healthVM: HealthViewModel
    @Binding var showingGoalSheet: Bool

    var body: some View {
        if let goal = healthVM.stepVM.dailyStepGoal {
            HStack {
                Text("🎯 Objectif quotidien :")
                Spacer()
                Text("\(goal)")
                    .bold()
                Button(action: { showingGoalSheet = true }) {
                    Image(systemName: "pencil")
                }
                .buttonStyle(.plain)
                .padding(.leading, 8)
            }
            .padding()
            .background(Color.green.opacity(0.2))
            .cornerRadius(8)
        } else {
            HStack {
                Text("🎯 Définir votre objectif quotidien de pas")
                Spacer()
                Button("Définir") {
                    showingGoalSheet = true
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(8)
        }
    }
}

#Preview {
    StepsView()
        .environmentObject(HealthViewModel())
}
