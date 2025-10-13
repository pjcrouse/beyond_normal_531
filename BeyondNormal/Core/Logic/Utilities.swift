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

/// Materially distinct and common 1RM formulas.
/// (Wendler removed — it's algebraically the same as Epley.)
public enum OneRepMaxFormula: String, CaseIterable {
    case epley    // 1RM ≈ w * (1 + reps/30)
    case brzycki  // 1RM ≈ w * (36 / (37 - reps))
    case mayhew   // 1RM ≈ (100*w) / (52.2 + 41.9*e^(−0.055*reps))
}
extension OneRepMaxFormula {
    var displayName: String {
        switch self {
        case .epley:   return "Epley"
        case .brzycki: return "Brzycki"
        case .mayhew:  return "Mayhew"
        }
    }
    var description: String {
        switch self {
        case .epley:   return "Simple, widely used linear estimate (1 + reps/30)."
        case .brzycki: return "More conservative at high reps (36 / (37 − reps))."
        case .mayhew:  return "Bench-tested sigmoid model; realistic at higher reps."
        }
    }
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
///   - 13–hardCap → estimate (still valid; keep .lowConfidence or .none per policy)
///   - > hardCap:
///         if refuseAboveHardCap == true → return 0 + .invalidTooManyReps
///         else → compute using hardCap reps + .capped(at: hardCap)
public func estimate1RM(
    weight: Double,
    reps: Int,
    formula: OneRepMaxFormula = .epley,
    softWarnAt: Int = 11,       // start warning at 11–12
    hardCap: Int = 15,          // beyond this, either refuse or cap (also keeps Brzycki safe)
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

/// Core formula implementations.
/// Note: With hardCap default = 15, Brzycki stays away from the r→37 asymptote.
private func rawEstimate(weight: Double, reps: Int, formula: OneRepMaxFormula) -> Double {
    switch formula {
    case .epley:
        return weight * (1.0 + Double(reps) / 30.0)

    case .brzycki:
        // 1RM = w * (36 / (37 - r))
        // Defensive clamp in case callers lift the hardCap elsewhere:
        let r = min(reps, 36) // avoid division by (37 - r) ≈ 0
        return weight * (36.0 / (37.0 - Double(r)))

    case .mayhew:
        // 1RM = (100*w) / (52.2 + 41.9 * e^(−0.055*r))
        return (100.0 * weight) / (52.2 + 41.9 * exp(-0.055 * Double(reps)))
    }
}
