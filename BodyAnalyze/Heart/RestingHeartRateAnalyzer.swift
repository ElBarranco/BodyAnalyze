//
//  RestingHeartRateAnalyzer.swift
//  BodyAnalyze
//
//  Created by Lionel Barranco on 15/05/2025.
//


import Foundation

class RestingHeartRateAnalyzer: ObservableObject {
    @Published var entries: [RestingHeartRateEntry] = []
    
    // Données triées par date croissante
    var sortedEntries: [RestingHeartRateEntry] {
        entries.sorted(by: { $0.date < $1.date })
    }

    // Moyenne glissante sur 7 jours
    var movingAverage: [Double] {
        let values = sortedEntries.map { Double($0.bpm) }
        var result: [Double] = []

        for i in 0..<values.count {
            if i < 6 {
                result.append(Double.nan) // pas assez de données pour 7 jours
            } else {
                let slice = values[(i - 6)...i]
                let avg = slice.reduce(0, +) / Double(slice.count)
                result.append(avg)
            }
        }

        return result
    }

    var averageLast7Days: Double {
        let recent = sortedEntries.suffix(7)
        guard !recent.isEmpty else { return 0.0 }
        return recent.map { Double($0.bpm) }.reduce(0, +) / Double(recent.count)
    }
    
    // Moyenne de référence (ex : sur 30 jours)
    var averageReference: Double {
        guard !entries.isEmpty else { return 0.0 }
        return entries.map { Double($0.bpm) }.reduce(0, +) / Double(entries.count)
    }

    // Retourne les alertes si +5 bpm au-dessus de la moyenne
    func isAboveThreshold(_ bpm: Int) -> Bool {
        return bpm > Int(averageReference) + 5
    }
}
