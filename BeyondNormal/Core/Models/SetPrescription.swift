//
//  SetPrescription.swift
//  BeyondNormal
//
//  Created by Pat Crouse on 10/24/25.
//

// Core/Models/SetPrescription.swift
import Foundation

/// A prescribed set (main, BBB, assistance, or Joker).
public struct SetPrescription: Identifiable, Hashable, Codable {
    public enum Kind: String, Codable { case main, bbb, assistance, joker }

    public let id: UUID
    public let kind: Kind
    public let percentOfTM: Double   // 1.00 = 100% TM
    public let reps: Int             // e.g., 5, 3, 1 (Joker: 3 or 1)
    public let weight: Double        // already rounded to settings.roundTo, if applicable
    public let label: String         // e.g., "Main", "BBB", "Joker", or UI label

    public init(
        id: UUID = UUID(),
        kind: Kind,
        percentOfTM: Double,
        reps: Int,
        weight: Double,
        label: String = "Joker"
    ) {
        self.id = id
        self.kind = kind
        self.percentOfTM = percentOfTM
        self.reps = reps
        self.weight = weight
        self.label = label
    }
}

// MARK: - Joker conveniences
public extension SetPrescription {
    static func jokerTriple(percentOfTM: Double, weight: Double) -> SetPrescription {
        .init(kind: .joker, percentOfTM: percentOfTM, reps: 3, weight: weight, label: "Joker")
    }
    static func jokerSingle(percentOfTM: Double, weight: Double) -> SetPrescription {
        .init(kind: .joker, percentOfTM: percentOfTM, reps: 1, weight: weight, label: "Joker")
    }
}
