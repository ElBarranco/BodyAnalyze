import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var viewModel: HealthViewModel

    var body: some View {
        TabView {


            HeartView()
                .tabItem {
                    Image(systemName: "heart.fill")
                    Text("Cœur")
                }

            TrainingView()
                .tabItem {
                    Image(systemName: "figure.strengthtraining.traditional")
                    Text("Entraînement")
                }
            
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
            
            CalorieView()
                .tabItem {
                    Image(systemName: "flame.fill")
                    Text("Calories")
                }

            StepsView()
                .tabItem {
                    Image(systemName: "shoeprints.fill")
                    Text("Pas")
                }
            /*
            RunningAnalysisView()
                .tabItem {
                    Image(systemName: "figure.run")
                    Text("Course")
                }*/
        }
    }
}
