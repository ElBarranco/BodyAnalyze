//
//  GlycogenLoadLevel.swift
//  BodyAnalyze
//
//  Created by Lionel Barranco on 13/05/2025.
//


import Foundation

/// Niveau de recharge glycogénique déclaré par l’utilisateur
enum GlycogenLoadLevel: String, CaseIterable, Identifiable {
    case low = "Basse"
    case normal = "Normale"
    case high = "Élevée"
    case full = "Totale"

    var id: String { rawValue }

    /// Pourcentage de remplissage estimé
    var percentageOfMax: Double {
        switch self {
        case .low: return 0.5
        case .normal: return 0.7
        case .high: return 0.9
        case .full: return 1.0
        }
    }
}