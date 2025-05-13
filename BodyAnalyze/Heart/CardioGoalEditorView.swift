import SwiftUI

struct CardioGoalEditorView: View {
    @Binding var goals: [Int: Double]  // la vraie source
    @Environment(\.dismiss) var dismiss

    @State private var localGoals: [Int: Double] = [2: 50, 3: 30, 4: 20]

    var total: Double {
        localGoals.values.reduce(0, +)
    }

    var body: some View {
        NavigationView {
            Form {
                ForEach([2, 3, 4], id: \.self) { (zone: Int) in
                    HStack {
                        Text("Zone \(zone)")
                        Slider(value: Binding(get: {
                            localGoals[zone] ?? 0
                        }, set: {
                            localGoals[zone] = round($0 / 5) * 5
                        }), in: 0...100, step: 5)
                        Text("\(localGoals[zone] ?? 0, specifier: "%.0f")%")
                            .frame(width: 40)
                    }
                }

                Text("Total : \(total, specifier: "%.0f")%")
                    .foregroundColor(total == 100 ? .green : .red)

                Section {
                    Button(action: {
                        goals = localGoals // ✅ Mise à jour réelle ici
                        dismiss()
                    }) {
                        HStack {
                            Spacer()
                            Text("✅ Mettre à jour l’objectif")
                                .foregroundColor(.white)
                                .bold()
                            Spacer()
                        }
                        .padding()
                        .background(total == 100 ? Color.blue : Color.gray)
                        .cornerRadius(10)
                    }
                    .disabled(total != 100)
                }
            }
            .navigationTitle("🎯 Objectifs cardio")
            .onAppear {
                self.localGoals = goals // 🧠 Copy locale pour édition isolée
            }
        }
    }
}
