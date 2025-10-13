import Foundation

// MARK: - Types

struct WarmupStep: Identifiable, Equatable {
    let id = UUID()
    let weight: Double
    let reps: Int

    init(weight: Double, reps: Int) {
        self.weight = weight
        self.reps = reps
    }
}

// MARK: - Suggestions

func suggestedMovement(for lift: Lift) -> String {
    switch lift {
    case .squat:    return "5 min easy bodyweight squats / hip hinges"
    case .deadlift: return "5 min kettlebell swings / RDL pattern"
    case .bench:    return "5 min pushups / banded push-aparts"
    case .row:      return "5 min band rows / scap retractions"
    case .press:    return "5 min band shoulder series / light DB press"
    }
}

// MARK: - Planner (lean: max 4 total sets, usually 2–3)

/// Builds a short ramp from bar → first working set (exclusive).
/// - Always starts with the bar (×10)
/// - Total sets capped at 4 (bar + up to 3 warmups)
/// - Usually gives 2–3 total sets depending on the jump.
/// - Rounds and de-dupes after rounding.
func buildWarmupPlan(target: Double, bar: Double, roundTo: Double) -> [WarmupStep] {
    // Guard rails
    guard target.isFinite, bar.isFinite, target > bar else {
        return [WarmupStep(weight: bar, reps: 10)]
    }

    @inline(__always) func r(_ x: Double) -> Double { LoadRounder.round(x, to: roundTo) }

    var steps: [WarmupStep] = [.init(weight: r(bar), reps: 10)]

    // How big is the jump from bar → first work set?
    let span = target - bar

    // Decide how many intermediate steps we want (bar not counted).
    // Goal: usually 1–2 steps; 3 only for big jumps.
    // You can tweak thresholds if you want even fewer sets.
    let stepCount: Int = {
        switch span {
        case ..<60:      return 1   // bar + 1 = 2 total
        case 60..<120:   return 2   // bar + 2 = 3 total
        default:         return 3   // bar + 3 = 4 total (cap)
        }
    }()

    // Percent templates for 1/2/3 steps.
    // These are *between* bar and target (exclusive), then rounded.
    let pctTemplates: [[Double]] = [
        [0.70],                  // 1 step
        [0.55, 0.75],           // 2 steps
        [0.50, 0.70, 0.85]      // 3 steps
    ]

    let pcts = pctTemplates[min(stepCount, 3) - 1]

    // Turn into candidate weights, clamp to be strictly between bar and target
    // after rounding, then de-dupe & sort.
    var candidates = pcts
        .map { r(target * $0) }
        .filter { $0 > bar && $0 < target }

    // De-dupe after rounding
    candidates = Array(Set(candidates)).sorted()

    // If rounding caused duplicates that trimmed us too much (e.g., all collapsed),
    // fall back to simple midpoints to ensure at least one useful touch.
    if candidates.isEmpty && stepCount > 0 {
        let mid = r((bar + target) / 2.0)
        if mid > bar && mid < target { candidates = [mid] }
    }

    // Cap to at most 3 candidates (bar + 3 = 4 total)
    if candidates.count > 3 { candidates = Array(candidates.prefix(3)) }

    // Assign quick rep targets by proximity to the work set
    func suggestedReps(_ w: Double) -> Int {
        let pct = w / target
        switch pct {
        case ..<0.60: return 8
        case ..<0.75: return 5
        case ..<0.87: return 3
        default:      return 1
        }
    }

    for w in candidates {
        if steps.last?.weight != w {
            steps.append(.init(weight: w, reps: suggestedReps(w)))
        }
    }

    // Final safety: ensure strictly less than target
    steps = steps.filter { $0.weight < target }

    // Absolute cap: bar + up to 3 = 4 total
    if steps.count > 4 { steps = Array(steps.prefix(4)) }

    // If we somehow ended with only the bar and the jump is large, add a midpoint
    if steps.count == 1 && span >= 60 {
        let mid = r((bar + target) * 0.7)
        if mid > bar && mid < target {
            steps.append(.init(weight: mid, reps: suggestedReps(mid)))
        }
    }

    return steps
}
