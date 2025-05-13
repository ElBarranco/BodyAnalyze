import SwiftUI

struct CalorieGraphView: View {
    var calorieData: [Date: Double]

    @State private var calorieIntake: [Date: Int] = [:]
    @State private var selectedDate: Date? = nil
    @State private var showPopup: Bool = false
    @State private var newCalorieInput: String = ""
    @FocusState private var isInputFocused: Bool

    private let storageKey = "CalorieIntakeStorage"

    // 📆 Tous les jours de la semaine (L → D)
    var currentWeekDates: [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)) else {
            return []
        }

        return (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: startOfWeek)
        }
    }

    var maxCalorieValue: Double {
        let maxBurned = calorieData.values.max() ?? 1
        let maxIntake = calorieIntake.values.map(Double.init).max() ?? 1
        return max(maxBurned, maxIntake)
    }

    var body: some View {
        ZStack {
            VStack(spacing: 24) {
                Text("🔥 Calories Dépensées vs Ingestées")
                    .font(.title2)
                    .bold()

                // 📊 Grille avec alignement en bas
                GeometryReader { geo in
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 16) {
                        ForEach(currentWeekDates, id: \.self) { date in
                            let burned = calorieData[date] ?? 0
                            let intake = calorieIntake[date]
                            let heightRatio = 150.0 / maxCalorieValue
                            let balance = (intake ?? 0) - Int(burned)
                            let isFutureDay = Calendar.current.startOfDay(for: date) > Calendar.current.startOfDay(for: Date())

                            ZStack(alignment: .bottom) {
                                VStack(spacing: 6) {
                                    // 📈 Bilan
                                    if intake != nil {
                                        Text(bilanText(for: balance))
                                            .font(.caption2)
                                            .foregroundColor(balance >= 0 ? .red : .green)
                                    }

                                    // 🔢 Totaux
                                    if let intake = intake {
                                        Text("\(intake)")
                                            .font(.caption2)
                                            .foregroundColor(.blue)
                                    }

                                    Text("\(Int(burned))")
                                        .font(.caption2)
                                        .foregroundColor(burned > 0 ? .orange : .gray)

                                    // 📊 Barres
                                    HStack(alignment: .bottom, spacing: 4) {
                                        Capsule()
                                            .fill(burned > 0 ? Color.orange : Color.gray.opacity(0.2))
                                            .frame(width: 6, height: max(1, CGFloat(burned * heightRatio)))
                                            .animation(.easeOut, value: burned)

                                        Capsule()
                                            .fill(intake != nil ? Color.blue : Color.gray.opacity(0.2))
                                            .frame(width: 6, height: max(1, CGFloat(Double(intake ?? 0) * heightRatio)))
                                            .animation(.easeOut, value: intake)
                                    }
                                    .frame(height: 150)

                                    // 📅 Jour
                                    Text(shortDate(date))
                                        .font(.caption2)

                                    // ✏️ ou ➕ Bouton (pas pour les jours futurs)
                                    if !isFutureDay {
                                        Button(action: {
                                            selectedDate = date
                                            newCalorieInput = intake != nil ? "\(intake!)" : ""
                                            showPopup = true
                                        }) {
                                            ZStack {
                                                if intake != nil {
                                                    Circle()
                                                        .fill(Color.green.opacity(0.2))
                                                        .frame(width: 30, height: 30)
                                                }
                                                Image(systemName: intake != nil ? "pencil.circle.fill" : "plus.circle.fill")
                                                    .font(.system(size: 18))
                                                    .foregroundColor(.blue)
                                            }
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .frame(maxHeight: .infinity)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(height: 320)
            }
            .padding()
            .onAppear {
                loadStoredCalories()
            }

            // 🪄 Popup
            if showPopup, let date = selectedDate {
                Color.black.opacity(0.4).ignoresSafeArea()

                VStack(spacing: 16) {
                    Text("Calories ingérées pour \(shortDate(date))")
                        .font(.headline)

                    TextField("Ex: 2100", text: $newCalorieInput)
                        .keyboardType(.numberPad)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .frame(width: 200)
                        .focused($isInputFocused)

                    HStack(spacing: 20) {
                        Button("Annuler") {
                            showPopup = false
                            newCalorieInput = ""
                        }
                        .foregroundColor(.red)

                        Button("Enregistrer ✅") {
                            if let intake = Int(newCalorieInput) {
                                calorieIntake[date] = intake
                                saveCalories()
                            }
                            newCalorieInput = ""
                            showPopup = false
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(20)
                .shadow(radius: 10)
                .frame(width: 300)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        isInputFocused = true
                    }
                }
            }
        }
    }

    // 📅 Format court
    private func shortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "E"
        return formatter.string(from: date).capitalized
    }

    // ➕ / ➖
    private func bilanText(for value: Int) -> String {
        return value >= 0 ? "+\(value) kcal" : "\(value) kcal"
    }

    // 💾 Sauvegarde UserDefaults
    private func saveCalories() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dataToStore = calorieIntake.reduce(into: [String: Int]()) { result, pair in
            result[formatter.string(from: pair.key)] = pair.value
        }
        UserDefaults.standard.set(dataToStore, forKey: storageKey)
    }

    // 📦 Chargement
    private func loadStoredCalories() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let saved = UserDefaults.standard.dictionary(forKey: storageKey) as? [String: Int] {
            let result = saved.compactMap { key, value -> (Date, Int)? in
                if let date = formatter.date(from: key) {
                    return (date, value)
                }
                return nil
            }
            self.calorieIntake = Dictionary(uniqueKeysWithValues: result)
        }
    }
}
