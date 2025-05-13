//
//  WeeklyExerciseView.swift
//  BodyAnalyze
//
//  Created by Lionel Barranco on 13/05/2025.
//


//
//  WeeklyExerciseView.swift
//  BodyAnalyze
//
//  Created by Lionel Barranco on 13/05/2025.
//

import SwiftUI

struct WeeklyExerciseView: View {
    @EnvironmentObject var healthVM: HealthViewModel
    private let title = "Sport 🏃‍♂️"
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.headline)
            Text(healthVM.trainingVM.weeklyWorkoutDisplay)
                .font(.largeTitle)
                .bold()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
        .onAppear {
            healthVM.trainingVM.loadWeeklyWorkoutMinutes()
        }
    }
}

#if DEBUG
struct WeeklyExerciseView_Previews: PreviewProvider {
    static var previews: some View {
        WeeklyExerciseView()
            .environmentObject(HealthViewModel())
            .previewLayout(.sizeThatFits)
            .padding()
    }
}
#endif