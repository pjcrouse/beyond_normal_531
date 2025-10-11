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
    }
}

// MARK: - Planner

/// Builds a ramp from bar → first working set (exclusive). Always starts with bar.
/// Steps auto-thin if the target is light, and de-dupe after rounding.
func buildWarmupPlan(target: Double, bar: Double, roundTo: Double) -> [WarmupStep] {
    guard target.isFinite, bar.isFinite, target > bar else {
        return [WarmupStep(weight: bar, reps: 10)]
    }

    @inline(__always) func r(_ x: Double) -> Double {
        LoadRounder.round(x, to: roundTo)
    }

    let base: [(pct: Double, reps: Int)] = [
        (0.40, 8), (0.55, 5), (0.70, 3), (0.80, 2), (0.90, 1)
    ]

    var steps: [WarmupStep] = []
    steps.append(.init(weight: r(bar), reps: 10))

    var candidates = base
        .map { r(target * $0.pct) }
        .filter { $0 > bar && $0 < target }

    let span = target - bar
    candidates = Array(Set(candidates)).sorted()

    switch span {
    case ...85:
        var high = r(target * 0.90)
        if high >= target { high = r(target - roundTo) }
        if high <= bar { high = r(bar + 20) }

        let mid = r((bar + high) / 2.0)

        var twoTouch = [mid, high].filter { $0 > bar && $0 < target }
        twoTouch = Array(Set(twoTouch)).sorted()

        if twoTouch.count == 1, twoTouch.first == high {
            let nudged = r(high - roundTo)
            if nudged > bar { twoTouch = [nudged, high] }
        }
        candidates = twoTouch

    case 86...110:
        if candidates.count >= 3 {
            let low  = candidates.first!
            let mid  = candidates[candidates.count / 2]
            let high = candidates.last!
            candidates = [low, mid, high]
        }

    default:
        break
    }

    for w in candidates {
        let pct = w / target
        let reps: Int = {
            switch pct {
            case ..<0.50: return 8
            case ..<0.70: return 5
            case ..<0.82: return 3
            case ..<0.92: return 2
            default:      return 1
            }
        }()
        if steps.last?.weight != w {
            steps.append(.init(weight: w, reps: reps))
        }
    }

    steps = steps.sorted { $0.weight < $1.weight }
        .filter { $0.weight < target }

    if steps.count == 1, target - bar >= 20 {
        let mid = r((target + bar) / 2.0)
        if mid > bar, mid < target {
            steps.insert(.init(weight: mid, reps: 3), at: 1)
        }
    }
    return steps
}
