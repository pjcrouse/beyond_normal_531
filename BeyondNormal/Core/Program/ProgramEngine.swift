import Foundation

// Keep these names identical so you don't have to touch any UI code yet.
struct SetScheme { let pct: Double; let reps: Int; let amrap: Bool }

struct WeekSchemeResult {
    let main: [SetScheme]
    let showBBB: Bool
    let topLine: String
}

enum ProgressionStyle: String {
    case classic   // steady +5/+10 per cycle
    case auto      // set TM to ~90% of latest AMRAP est 1RM (with caps)
}

/// Pure 5/3/1 rules — no SwiftUI, no persistence.
/// This keeps the “program math” isolated and easy to unit test later.
struct ProgramEngine {

    func weekScheme(for week: Int) -> WeekSchemeResult {
        switch week {
        case 2:
            return .init(
                main: [.init(pct:0.70, reps:3, amrap:false),
                       .init(pct:0.80, reps:3, amrap:false),
                       .init(pct:0.90, reps:3, amrap:true)],
                showBBB: true,
                topLine: "90% × 3+"
            )
        case 3:
            return .init(
                main: [.init(pct:0.75, reps:5, amrap:false),
                       .init(pct:0.85, reps:3, amrap:false),
                       .init(pct:0.95, reps:1, amrap:true)],
                showBBB: true,
                topLine: "95% × 1+"
            )
        case 4:
            return .init(
                main: [.init(pct:0.40, reps:5, amrap:false),
                       .init(pct:0.50, reps:5, amrap:false),
                       .init(pct:0.60, reps:5, amrap:false)],
                showBBB: false,
                topLine: "Deload: 60% × 5"
            )
        default:
            return .init(
                main: [.init(pct:0.65, reps:5, amrap:false),
                       .init(pct:0.75, reps:5, amrap:false),
                       .init(pct:0.85, reps:5, amrap:true)],
                showBBB: true,
                topLine: "85% × 5+"
            )
        }
    }

    /// Not wired yet — we’ll use this in a later step when we refactor TM updates.
    /// - Parameters:
    ///   - isUpperBody: true for BP/ROW, false for SQ/DL (caps differ)
    func nextTrainingMax(
        current: Double,
        latestAMRAP1RM: Double?,
        style: ProgressionStyle,
        isUpperBody: Bool
    ) -> Double {
        switch style {
        case .classic:
            // +5 upper / +10 lower per cycle
            return current + (isUpperBody ? 5 : 10)
        case .auto:
            guard let latest = latestAMRAP1RM, latest > 0 else { return current }
            // 90% of latest AMRAP 1RM, but cap the increase per cycle
            let proposed = latest * 0.90
            let cap = isUpperBody ? 10.0 : 20.0
            return min(current + cap, proposed)
        }
    }
}
