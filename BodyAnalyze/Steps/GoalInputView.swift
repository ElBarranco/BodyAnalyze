// GoalInputView.swift

import SwiftUI

struct GoalInputView: View {
    @Binding var goal: Int?
    @Environment(\.presentationMode) private var presentationMode
    @State private var inputText: String = ""
    @FocusState private var isFocused: Bool    // ← ajout

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Text("Entrez votre objectif quotidien de pas")
                    .font(.headline)

                TextField("Nombre de pas", text: $inputText)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
                    .focused($isFocused)              // ← rattacher le focus
                    .onAppear {
                        // petit délai pour que le TextField soit déjà dans la hiérarchie
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            self.isFocused = true       // ← ouvre le clavier immédiatement
                        }
                    }

                Spacer()

                Button("Enregistrer") {
                    if let val = Int(inputText), val > 0 {
                        goal = val
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(Int(inputText) == nil)
            }
            .padding()
            .navigationTitle("Objectif Pas")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}
