//
//  JokerSetGenerator.swift
//  BeyondNormal
//

import Foundation

public struct JokerParams: Sendable, Hashable {
    public var tripleStepPct: Double   // e.g., 0.05 (5%)
    public var singleStepPct: Double   // e.g., 0.10 (10%)
    public var maxOverTMPct: Double    // e.g., 0.20 (20%) max from settings
    public var allowSecondTriple: Bool // kept for backward-compat; UI feedback now controls progression
    public var roundTo: Double         // e.g., 2.5 or 5.0

    public init(
        tripleStepPct: Double,
        singleStepPct: Double,
        maxOverTMPct: Double,
        allowSecondTriple: Bool,
        roundTo: Double
    ) {
        self.tripleStepPct = tripleStepPct
        self.singleStepPct = singleStepPct
        self.maxOverTMPct = maxOverTMPct
        self.allowSecondTriple = allowSecondTriple
        self.roundTo = roundTo
    }
}

/// Central generator for Joker sets.
public enum JokerSetGenerator {

    /// Generate the **full** candidate sequence given TM, week, and params.
    /// (Your UI can still reveal these progressively via feedback.)
    public static func generate(
        trainingMax: Double,
        week: WeekKind,
        params: JokerParams
    ) -> [SetPrescription] {

        let roundTo = params.roundTo > 0 ? params.roundTo : 5.0
        // Respect both the user cap and a hard ceiling of +20% (1.20x TM).
        let maxPct = min(1.00 + params.maxOverTMPct, 1.20)

        switch week {
        case .five:
            return []

        case .three:
            // Start at 95% TM; step by tripleStepPct (default 5%) up to maxPct.
            var pcts: [Double] = []
            var p = 0.95
            while p <= maxPct + 1e-9 {
                pcts.append(p)
                p += params.tripleStepPct
            }
            return pcts.map { pct in
                let w = round(trainingMax * pct / roundTo) * roundTo
                return .jokerTriple(percentOfTM: pct, weight: w)
            }

        case .one:
            // Start at 100% TM; step by singleStepPct (default 10%) up to maxPct.
            var pcts: [Double] = []
            var p = 1.00
            while p <= maxPct + 1e-9 {
                pcts.append(p)
                p += params.singleStepPct
            }
            return pcts.map { pct in
                let w = round(trainingMax * pct / roundTo) * roundTo
                return .jokerSingle(percentOfTM: pct, weight: w)
            }
        }
    }

    /// Convenience: given what you’ve already added, return the **next** set (or nil if capped).
    public static func next(
        trainingMax: Double,
        week: WeekKind,
        params: JokerParams,
        after existing: [SetPrescription]
    ) -> SetPrescription? {
        // Build the full plan, then pick the first one you haven’t done yet.
        let all = generate(trainingMax: trainingMax, week: week, params: params)
        guard let last = existing.last else { return all.first }
        guard let idx = all.firstIndex(where: { $0.percentOfTM == last.percentOfTM && $0.reps == last.reps }) else {
            return nil
        }
        let nextIdx = all.index(after: idx)
        return nextIdx < all.endIndex ? all[nextIdx] : nil
    }
}
