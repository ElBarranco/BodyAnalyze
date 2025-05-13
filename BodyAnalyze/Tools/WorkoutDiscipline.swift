//
//  WorkoutDiscipline.swift
//  BodyAnalyze
//
//  Created by Lionel Barranco on 07/05/2025.
//


enum WorkoutDiscipline: String {
    case running
    case hiking
    case strength
    case cycling
    case swimming
    case unknown

    var icon: String {
        switch self {
        case .running: return "figure.run"
        case .hiking: return "figure.hiking"
        case .strength: return "dumbbell"
        case .cycling: return "bicycle"
        case .swimming: return "figure.pool.swim"
        case .unknown: return "questionmark"
        }
    }

    var label: String {
        switch self {
        case .running: return "Course"
        case .hiking: return "Rando"
        case .strength: return "Muscu"
        case .cycling: return "Vélo"
        case .swimming: return "Natation"
        case .unknown: return "Inconnu"
        }
    }
}