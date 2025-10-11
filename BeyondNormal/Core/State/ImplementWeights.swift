import Foundation
import SwiftUI

final class ImplementWeights: ObservableObject {
    static let shared = ImplementWeights()
    private init() { load() }

    // Single JSON blob in @AppStorage
    @AppStorage("implement_weights_json") private var raw: String = ""

    // In-memory map: exerciseID -> implement (bar) weight in lb
    @Published private(set) var map: [String: Double] = [:]

    // Defaults (tweak as needed). Keys:
    // - Main lifts use Lift.rawValue ("SQ","BP","DL","RW")
    // - Assistance uses AssistanceExercise.id
    private let defaults: [String: Double] = [
        // Main lifts
        "SQ": 75,   // SSB for squat day
        "BP": 45,
        "DL": 45,
        "RW": 45,

        // Barbell/EZ assistance examples
        "front_squat": 45,
        "paused_squat": 45,
        "close_grip": 45,
        "triceps_ext": 25 // typical EZ-bar
    ]

    func load() {
        guard let data = raw.data(using: .utf8), !raw.isEmpty,
              let decoded = try? JSONDecoder().decode([String: Double].self, from: data) else {
            map = defaults
            persist()
            return
        }
        // Merge: keep new defaults if added in future
        var merged = defaults
        decoded.forEach { merged[$0] = $1 }
        map = merged
        persist()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(map),
           let json = String(data: data, encoding: .utf8) {
            raw = json
        }
    }

    func weight(for exerciseID: String) -> Double {
        map[exerciseID] ?? defaults[exerciseID] ?? 45
    }

    func weight(for lift: Lift) -> Double {
        weight(for: lift.rawValue)
    }

    func setWeight(_ w: Double, for exerciseID: String) {
        map[exerciseID] = max(1, min(w, 200))
        persist()
        objectWillChange.send()
    }

    func restoreDefaults() {
        map = defaults
        persist()
        objectWillChange.send()
    }
}
