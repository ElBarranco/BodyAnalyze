//
//  EnergyExpenditureModel.swift
//  BodyAnalyze
//
//  Created by Lionel Barranco on 13/05/2025.
//


import Foundation

enum EnergyExpenditureModel {
    static func kcalPerKgPerHour(for activity: ActivityType, intensity: String) -> Double {
        switch activity {
        case .run:
            switch intensity {
            case "Z1": return 8.0
            case "Z2": return 10.0
            case "Z3": return 12.5
            case "Z4": return 14.5
            case "Z5": return 16.5
            default:   return 10.0
            }
        case .trail:
            switch intensity {
            case "Z1": return 7.5
            case "Z2": return 9.5
            case "Z3": return 11.5
            case "Z4": return 13.5
            case "Z5": return 15.5
            default:   return 9.0
            }
        case .hike:
            switch intensity {
            case "Z1": return 6.0
            case "Z2": return 8.0
            case "Z3": return 10.0
            case "Z4": return 12.0
            case "Z5": return 13.0
            default:   return 7.0
            }
        case .bike:
            switch intensity {
            case "Z1": return 5.5
            case "Z2": return 7.5
            case "Z3": return 9.0
            case "Z4": return 11.0
            case "Z5": return 13.0
            default:   return 7.0
            }
        case .ski:
            switch intensity {
            case "Z1": return 7.0
            case "Z2": return 9.0
            case "Z3": return 11.0
            case "Z4": return 13.0
            case "Z5": return 15.0
            default:   return 9.0
            }
        }
    }
}
