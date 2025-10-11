import Foundation

// MARK: - General utilities

/// Round to the nearest increment (e.g., 5 lb)
func roundToNearest(_ value: Double, step: Double = 5.0) -> Int {
    Int((value / step).rounded() * step)
}

/// Recommend per-hand load for DB RDL from Deadlift TM.
/// Defaults: ~18% of DL TM per hand, rounded to nearest 5 lb, floor 20 lb.
func recommendedDBRDLPerHand(deadliftTM: Double, roundTo step: Double = 5.0) -> Int {
    let perHand = deadliftTM * 0.14
    return max(20, roundToNearest(perHand, step: step))
}

/// Recommend total bar weight for SSB Good Morning from Deadlift TM.
/// ~30% of Deadlift TM on the bar, rounded, clamped to at least the SSB bar weight.
func recommendedSSBGMWeight(deadliftTM: Double, barWeight: Double, roundTo step: Double = 5.0) -> Int {
    let target = deadliftTM * 0.30
    let rounded = roundToNearest(target, step: step)
    return max(Int(barWeight), rounded)
}
