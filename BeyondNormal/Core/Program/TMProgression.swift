import Foundation

// Keep these internal
struct TMSet {
    var squat: Double
    var bench: Double
    var deadlift: Double
    var row: Double
    var press: Double
}

enum TMProgressionStyle: String {
    case classic
    case auto
}

extension TMSet {
    func value(for lift: Lift) -> Double {
        switch lift {
        case .squat: return squat
        case .bench: return bench
        case .deadlift: return deadlift
        case .row: return row
        case .press: return press
        }
    }

    mutating func bump(_ lift: Lift, by delta: Double) {
        switch lift {
        case .squat:    squat    += delta
        case .bench:    bench    += delta
        case .deadlift: deadlift += delta
        case .row:      row      += delta
        case .press:    press    += delta
        }
    }
}

// ---- Classic: +5 upper, +10 lower (internal) ----
func applyClassic(_ tms: inout TMSet, active: [Lift]) {
    for lift in active {
        let delta: Double = lift.isUpperBody ? 5 : 10
        tms.bump(lift, by: delta)
    }
}

// ---- Auto: 90% of best est-1RM, capped/floored per cycle (internal) ----
// Defaults: cap = 10 upper / 20 lower, floor = 2.5 upper / 5 lower
func applyAuto(_ tms: inout TMSet, active: [Lift], entries: [WorkoutEntry]) {
    // build quick lookup: best est-1RM per lift for the most recent cycle in entries
    // (if you’re already passing “recent” entries = last cycle, this is trivial)
    var bestByLift: [String: Int] = [:]
    for e in entries where e.est1RM > 0 {
        // keep the max for each lift label
        bestByLift[e.lift] = max(bestByLift[e.lift] ?? 0, Int(e.est1RM.rounded()))
    }

    func classicBump(_ lift: Lift) -> Double {
        lift.isUpperBody ? 5 : 10
    }

    for lift in active {
        // current TM
        let current: Double = {
            switch lift {
            case .squat:    return tms.squat
            case .bench:    return tms.bench
            case .deadlift: return tms.deadlift
            case .row:      return tms.row
            case .press:    return tms.press
            }
        }()

        guard let best = bestByLift[lift.label], best > 0 else {
            // No AMRAP data → apply floor bump (0.5x classic)
            let floorDelta = classicBump(lift) * 0.5
            let next = current + floorDelta
            switch lift {
            case .squat:    tms.squat    = next
            case .bench:    tms.bench    = next
            case .deadlift: tms.deadlift = next
            case .row:      tms.row      = next
            case .press:    tms.press    = next
            }
            continue
        }

        // target TM = 90% of best est-1RM (rounded)
        let targetTM = Double(best).rounded() * 0.90

        let rawDelta = max(targetTM - current, 0) // never go down
        let minDelta = classicBump(lift) * 0.5    // floor
        let maxDelta = classicBump(lift) * 2.0    // cap

        let clampedDelta = max(minDelta, min(rawDelta, maxDelta))
        let next = current + clampedDelta

        switch lift {
        case .squat:    tms.squat    = next
        case .bench:    tms.bench    = next
        case .deadlift: tms.deadlift = next
        case .row:      tms.row      = next
        case .press:    tms.press    = next
        }
    }
}
