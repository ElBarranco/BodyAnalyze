//
//  RestingHeartRateEntry.swift
//  BodyAnalyze
//
//  Created by Lionel Barranco on 15/05/2025.
//


import Foundation

struct RestingHeartRateEntry: Identifiable {
    let id = UUID()
    let date: Date
    let bpm: Int
}