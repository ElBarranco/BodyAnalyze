//
//  WellbeingScoreTile.swift
//  BodyAnalyze
//
//  Created by Lionel Barranco on 25/05/2025.
//


import SwiftUI

struct WellbeingScoreTile: View {
    let title: String
    let score: Double // sur 10
    let color: Color

    var body: some View {
        VStack(spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)

            ZStack(alignment: .bottom) {
                Capsule()
                    .frame(width: 20, height: 100)
                    .foregroundColor(Color.gray.opacity(0.2))

                Capsule()
                    .frame(width: 20, height: CGFloat(score / 10.0 * 100))
                    .foregroundColor(color)
            }
            .animation(.easeInOut, value: score)

            Text("\(Int(score * 10)) / 100")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
