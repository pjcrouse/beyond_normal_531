import Foundation

// MARK: - General utilities

/// Round to the nearest increment (e.g., 5 lb)
func roundToNearest(_ value: Double, step: Double = 5.0) -> Int {
    Int((value / step).rounded() * step)
}

/// Recommend per-hand load for DB RDL from Deadlift TM.
/// Defaults: ~14% of DL TM per hand, rounded to nearest 5 lb, floor 20 lb.
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

// MARK: - AMRAP Estimation

public enum OneRepMaxFormula {
    case epley   // 1RM ≈ w * (1 + reps/30)
    case wendler // 1RM ≈ w * (1 + 0.0333 * reps)
}

/// UI/logic note about the quality or handling of the estimate.
public enum AmrapEstimateNote: Equatable {
    case none                      // 2–10 reps (or exactly 1 rep override)
    case lowConfidence             // 11–12 reps (still computed)
    case capped(at: Int)           // reps > hardCap AND we chose to cap
    case invalidTooManyReps(actual: Int) // reps > hardCap AND we chose to refuse
}

public struct AmrapEstimate {
    public let e1RM: Double        // already rounded to step
    public let note: AmrapEstimateNote
}

/// Estimate 1RM with guardrails & notes.
/// Policy:
///   - reps == 1 → e1RM = weight (no formula)
///   - 2–10 → normal estimate (.none)
///   - 11–12 → estimate + .lowConfidence
///   - 13–hardCap → estimate (still valid but on the edge; you may keep .lowConfidence or .none)
///   - > hardCap:
///         if refuseAboveHardCap == true → return 0 + .invalidTooManyReps
///         else → compute using hardCap reps + .capped(at: hardCap)
public func estimate1RM(
    weight: Double,
    reps: Int,
    formula: OneRepMaxFormula = .epley,
    softWarnAt: Int = 11,       // start warning at 11–12
    hardCap: Int = 15,          // beyond this, either refuse or cap
    refuseAboveHardCap: Bool = true,
    roundTo step: Double = 5.0
) -> AmrapEstimate {
    guard weight > 0, reps > 0 else {
        return AmrapEstimate(e1RM: 0, note: .none)
    }

    // Rule: exact single rep = working weight
    if reps == 1 {
        let rounded = Double(roundToNearest(weight, step: step))
        return AmrapEstimate(e1RM: rounded, note: .none)
    }

    // Handle > hardCap according to policy
    if reps > hardCap {
        if refuseAboveHardCap {
            return AmrapEstimate(e1RM: 0, note: .invalidTooManyReps(actual: reps))
        } else {
            // Cap and proceed
            let raw = rawEstimate(weight: weight, reps: hardCap, formula: formula)
            let rounded = Double(roundToNearest(raw, step: step))
            return AmrapEstimate(e1RM: rounded, note: .capped(at: hardCap))
        }
    }

    // Inside allowable range (2...hardCap)
    let raw = rawEstimate(weight: weight, reps: reps, formula: formula)
    let rounded = Double(roundToNearest(raw, step: step))

    // Confidence note
    let note: AmrapEstimateNote =
        (reps >= softWarnAt) ? .lowConfidence : .none

    return AmrapEstimate(e1RM: rounded, note: note)
}

private func rawEstimate(weight: Double, reps: Int, formula: OneRepMaxFormula) -> Double {
    switch formula {
    case .epley:
        return weight * (1.0 + Double(reps) / 30.0)
    case .wendler:
        return weight * (1.0 + 0.0333 * Double(reps))
    }
}
