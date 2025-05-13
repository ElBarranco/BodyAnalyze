import SwiftUI
import Charts
import UIKit

/// Struct pour mémoriser la sélection, conforme à Equatable
struct HRVSelection: Equatable {
    let date: Date
    let score: Double
    let rawValue: Double    // VFC brut (sdnn) en millisecondes
}

struct HRVChartView: View {
    @ObservedObject var vm: HeartMetricsViewModel

    // MARK: – États
    @State private var windowStart: Int = 0
    @State private var selectedSample: HRVSelection?
    @State private var displayedScore: Double = 0

    // MARK: – Constantes
    private let windowSize = 20
    private let chartHeight: CGFloat = 180
    private let maxScore: Double = 12.0
    private let feedback = UIImpactFeedbackGenerator(style: .light)

    // MARK: – Données brutes
    private var samples: [HRVSample] { vm.hrvSamples }

    // MARK: – Calculs intermédiaires
    private func resetToLatest() {
        windowStart = max(0, samples.count - windowSize)
        if let last = samples.last {
            let raw = last.value
            let score = vm.hrvScore(sdnn: raw)
            selectedSample = HRVSelection(date: last.date, score: score, rawValue: raw)
            displayedScore = score
        }
    }

    private var window: [HRVSample] {
        let start = min(windowStart, max(0, samples.count - windowSize))
        let end   = min(start + windowSize, samples.count)
        return Array(samples[start..<end])
    }

    /// Liste des tuples (date, score) filtrés sur des scores valides
    private var scoredData: [(date: Date, score: Double)] {
        window
            .map { sample in
                (date: sample.date, score: vm.hrvScore(sdnn: sample.value))
            }
            .filter { $0.score.isFinite }
    }

    /// Domaine X de type ClosedRange<Date>, avec fallback si vide
    private var domainRange: ClosedRange<Date> {
        if let first = scoredData.first?.date,
           let last  = scoredData.last?.date {
            return first...last
        } else {
            let today = Calendar.current.startOfDay(for: Date())
            return today...today
        }
    }

    private var pageInfo: String {
        let pages       = max(1, Int(ceil(Double(samples.count)/Double(windowSize))))
        let currentPage = min(windowStart/windowSize + 1, pages)
        return "Page \(currentPage) / \(pages)"
    }

    // MARK: – Vue
    var body: some View {
        VStack(spacing: 12) {
            // Header avec date, VFC brute et gauge dynamique
            if let sel = selectedSample {
                HRVHeader(
                    date: sel.date,
                    score: displayedScore,
                    rawValue: sel.rawValue,
                    maxScore: maxScore
                )
            }

            let data = scoredData

            Chart(data, id: \.date) { sample in
                let clamped = min(sample.score, maxScore)
                LineMark(
                    x: .value("Date", sample.date),
                    y: .value("Score", clamped)
                )
                PointMark(
                    x: .value("Date", sample.date),
                    y: .value("Score", clamped)
                )
                .symbolSize(sample.date == selectedSample?.date ? 200 : 80)
                .foregroundStyle(
                    sample.date == selectedSample?.date
                        ? .white
                        : .blue.opacity(0.7)
                )
            }
            .chartXScale(domain: domainRange)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { mark in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .chartYScale(domain: 0...maxScore)
            .frame(height: chartHeight)
            .padding(.horizontal, 8)
            .chartOverlay { proxy in
                GeometryReader { geo in
                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                        .gesture(
                            // Uniquement le tap (drag minDistance 0) sur onEnded
                            DragGesture(minimumDistance: 0)
                                .onEnded { value in
                                    let frame = geo[proxy.plotAreaFrame]
                                    let xPos  = value.location.x - frame.minX
                                    if let tappedDate: Date = proxy.value(atX: xPos),
                                       let nearest = data.min(by: {
                                           abs($0.date.timeIntervalSince(tappedDate))
                                             < abs($1.date.timeIntervalSince(tappedDate))
                                       }),
                                       let rawSample = window.first(where: { $0.date == nearest.date })
                                    {
                                        withAnimation(.easeInOut(duration: 0.1)) {
                                            selectedSample = HRVSelection(
                                                date: nearest.date,
                                                score: nearest.score,
                                                rawValue: rawSample.value
                                            )
                                            displayedScore = nearest.score
                                        }
                                        feedback.impactOccurred()
                                    }
                                }
                        )
                }
            }
            .gesture(
                // Pagination par swipe gauche/droite
                DragGesture()
                    .onEnded { value in
                        if value.translation.width < -50 { nextPage() }
                        else if value.translation.width > 50 { prevPage() }
                    }
            )

            // Pagination manuelle
            HStack {
                Button(action: prevPage) {
                    Image(systemName: "chevron.left")
                }
                .disabled(windowStart == 0)
                .opacity(windowStart == 0 ? 0.5 : 1)

                Spacer()

                Text(pageInfo)
                    .font(.caption)

                Spacer()

                Button(action: nextPage) {
                    Image(systemName: "chevron.right")
                }
                .disabled(windowStart >= samples.count - windowSize)
                .opacity(windowStart >= samples.count - windowSize ? 0.5 : 1)
            }
            .padding(.horizontal, 8)
        }
        .onAppear {
            feedback.prepare()
            resetToLatest()
        }
        .onReceive(vm.$hrvSamples) { _ in
            resetToLatest()
        }
    }

    // MARK: – Pagination
    private func prevPage() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            windowStart = max(0, windowStart - windowSize)
            if let lastSample = window.last {
                let raw   = lastSample.value
                let score = vm.hrvScore(sdnn: raw)
                selectedSample = HRVSelection(
                    date: lastSample.date,
                    score: score,
                    rawValue: raw
                )
                displayedScore = score
            }
        }
    }

    private func nextPage() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            windowStart = min(max(0, samples.count - windowSize),
                              windowStart + windowSize)
            if let lastSample = window.last {
                let raw   = lastSample.value
                let score = vm.hrvScore(sdnn: raw)
                selectedSample = HRVSelection(
                    date: lastSample.date,
                    score: score,
                    rawValue: raw
                )
                displayedScore = score
            }
        }
    }
}

/// Header animé avec gauge dynamique selon la note et affichage de la VFC brute
struct HRVHeader: View {
    let date: Date
    let score: Double
    let rawValue: Double
    let maxScore: Double

    private var clampedScore: Double { min(score, maxScore) }

    /// Détermine la couleur de la gauge selon la note
    private var gaugeColor: Color {
        switch clampedScore {
        case ..<2:     return .red
        case ..<4:     return .orange
        case ..<6:     return .yellow
        case ..<8:     return .blue
        case ..<10:    return Color(red: 0.0, green: 0.5, blue: 0.0)
        default:       return .green
        }
    }

    var body: some View {
        let label: String = {
            let r = clampedScore.rounded()
            return (r == clampedScore)
                ? "\(Int(r))"
                : String(format: "%.1f", clampedScore)
        }()

        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(date, style: .date)
                    Text("| VFC: \(Int(rawValue)) ms")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Text(date, style: .time)
                    .font(.subheadline)
            }

            Spacer()

            Gauge(value: clampedScore, in: 0...maxScore) {
                EmptyView()
            } currentValueLabel: {
                Text(label)
                    .font(.system(size: 32, weight: .bold))
            }
            .gaugeStyle(.accessoryCircular)
            .tint(gaugeColor)
            .frame(width: 80, height: 80)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(10)
        .padding(.horizontal)
    }
}
