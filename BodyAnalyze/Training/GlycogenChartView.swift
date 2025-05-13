//
//  GlycogenChartView.swift
//  BodyAnalyze
//
//  Created by Lionel Barranco on 13/05/2025.
//


import SwiftUI
import Charts

struct GlycogenChartView: View {
    let result: GlycogenEstimationResult
    let duration: Double
    @Binding var selectedIndex: Int?

    var body: some View {
        Chart {
            ForEach(Array(result.timeSeries.enumerated()), id: \.offset) { index, value in
                LineMark(
                    x: .value("Temps (h)", Double(index) / 100.0 * duration),
                    y: .value("Glycogène (g)", value)
                )
            }

            RuleMark(y: .value("Seuil de fatigue", result.reserveMax * 0.5))
                .foregroundStyle(.orange)
            RuleMark(y: .value("Zone critique", result.reserveMax * 0.3))
                .foregroundStyle(.red)

            if let i = selectedIndex {
                let x = Double(i) / 100.0 * duration
                let y = result.timeSeries[i]

                RuleMark(x: .value("Temps", x))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
                    .foregroundStyle(.blue)

                PointMark(
                    x: .value("Temps", x),
                    y: .value("Glycogène", y)
                )
                .symbolSize(60)
                .foregroundStyle(.blue)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading)
        }
        .frame(height: 250)
        .chartOverlay { proxy in
            GeometryReader { geo in
                Rectangle().fill(Color.clear).contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let x = value.location.x - geo[proxy.plotAreaFrame].origin.x
                                if let t = proxy.value(atX: x, as: Double.self) {
                                    let index = Int((t / duration) * 100)
                                    if index >= 0 && index < result.timeSeries.count {
                                        selectedIndex = index
                                    }
                                }
                            }
                    )
            }
        }    }
}
