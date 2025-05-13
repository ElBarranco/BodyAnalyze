//
//  ActivityType.swift
//  BodyAnalyze
//
//  Created by Lionel Barranco on 13/05/2025.
//


enum ActivityType: String, CaseIterable, Identifiable {
case hike = "Randonnée"
case trail = "Trail"
case run = "Course"
case bike = "Vélo"
case ski = "Ski de rando"

var id: String { rawValue }

var baseCoeff: Double {
    switch self {
    case .hike: return 0.55
    case .trail: return 0.65
    case .run: return 0.6
    case .bike: return 0.5
    case .ski: return 0.7
    }
}
}
