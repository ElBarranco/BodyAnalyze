import SwiftUI

struct RunningAnalysisView: View {
    @State private var lastSession: CourseMetrics?
    @State private var weeklyDistance: Double = 0.0
    @State private var groundContactTime: Double?
    @State private var strideLength: Double?
    @State private var isLoading = true
    @State private var showAllSessions = false

    private let courseManager = CourseManager()

    // 🆕 MOCK pour l'histogramme
    private let mockWeeklyDistances: [WeekDistance] = [
        WeekDistance(label: "S-6", distance: 22),
        WeekDistance(label: "S-5", distance: 28),
        WeekDistance(label: "S-4", distance: 31),
        WeekDistance(label: "S-3", distance: 26),
        WeekDistance(label: "S-2", distance: 18),
        WeekDistance(label: "S-1", distance: 24)
    ]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    
                    // 📈 Distance hebdo
                    WeeklyRunningDistanceWidget(distance: weeklyDistance)
                        .padding(.horizontal)
                    
                    // 📊 Histogramme sur 6 semaines
                    WeeklyRunningBarChartWidget(weeklyDistances: mockWeeklyDistances)
                        .padding(.horizontal)
                    
                    // 📊 ➡️ Moyenne sur 6 semaines
                    WeeklyAverageDistanceWidget(averageDistance: computeWeeklyAverage())
                        .padding(.horizontal)

                    // 🔄 Chargement
                    if isLoading {
                        ProgressView("Chargement de la dernière session...")
                            .padding()
                    }

                    // 🏃‍♂️ Infos dernière session
                    if let session = lastSession {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("🏃‍♂️ Dernière session")
                                .font(.headline)

                            VStack(alignment: .leading, spacing: 6) {
                                Text("📅 \(formattedDate(session.date))")
                                Text("🕒 Durée : \(formatDuration(session.duration))")
                                Text("📏 Distance : \(String(format: "%.2f km", session.distance))")
                                Text("👣 Cadence moyenne : \(Int(session.averageCadence)) spm")
                                Text("❤️ BPM moyen : \(Int(session.averageBPM)) bpm")
                            }
                            .font(.subheadline)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(16)
                        }
                        .padding(.horizontal)

                        // 🧱 Widgets analytiques
                        if let gct = groundContactTime {
                            GroundContactWidget(averageGCT: gct)
                                .padding(.horizontal)
                        }

                        if let stride = strideLength {
                            StrideLengthWidget(averageStride: stride)
                                .padding(.horizontal)
                        }
                    }

                    // 📂 Voir toutes les sessions
                    Button(action: {
                        showAllSessions = true
                    }) {
                        HStack {
                            Image(systemName: "folder")
                            Text("Voir toutes les sessions")
                        }
                        .font(.body)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)

                    Spacer()
                }
                .padding(.top)
            }
            .navigationTitle("Course à pied")
            .onAppear {
                loadLastSession()
                loadWeeklyDistance()
            }
            .sheet(isPresented: $showAllSessions) {
                AllRunningSessionsView()
            }
        }
    }

    // MARK: - Données

    private func loadLastSession() {
        isLoading = true

        courseManager.getLastRunningWorkout { workout in
            guard let workout = workout else {
                DispatchQueue.main.async {
                    self.isLoading = false
                }
                return
            }

            let metrics = CourseMetrics(
                date: workout.startDate,
                duration: workout.duration,
                distance: workout.totalDistance?.doubleValue(for: .meterUnit(with: .kilo)) ?? 0,
                averageBPM: 148,
                averageCadence: 164
            )

            DispatchQueue.main.async {
                self.lastSession = metrics
                self.isLoading = false
            }

            courseManager.getGroundContactTimeAverage(for: workout) { gct in
                DispatchQueue.main.async {
                    self.groundContactTime = gct
                }
            }

            courseManager.getAverageStrideLength(for: workout) { stride in
                DispatchQueue.main.async {
                    self.strideLength = stride
                }
            }
        }
    }

    private func loadWeeklyDistance() {
        courseManager.getWeeklyRunningDistance { distance in
            DispatchQueue.main.async {
                self.weeklyDistance = distance
            }
        }
    }

    // MARK: - Helpers

    private func computeWeeklyAverage() -> Double {
        let total = mockWeeklyDistances.map { $0.distance }.reduce(0, +)
        return total / Double(mockWeeklyDistances.count)
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration / 60)
        let seconds = Int(duration.truncatingRemainder(dividingBy: 60))
        return "\(minutes) min \(seconds) sec"
    }
}
