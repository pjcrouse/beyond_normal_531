import Foundation

struct ProgramWeekSummaryResult: Identifiable {
    let id = UUID()
    let cycle: Int
    let programWeek: Int
    let totalVolume: Int
    let lifts: [LiftSummary]

    struct LiftSummary: Identifiable {
        let id = UUID()
        let lift: String        // stored as label in entries
        let est1RM: Int         // best (latest) est1RM for this week/cycle
        let totalVolume: Int    // sum of volumes for this lift in this week/cycle
        let sessionCount: Int
    }
}

func computeProgramWeekSummary(
    cycle: Int,
    programWeek: Int,
    entries: [WorkoutEntry]
) -> ProgramWeekSummaryResult {
    let weekEntries = entries.filter { $0.cycle == cycle && $0.programWeek == programWeek }

    let grouped = Dictionary(grouping: weekEntries, by: { $0.lift })
    let lifts: [ProgramWeekSummaryResult.LiftSummary] = grouped.map { (lift, arr) in
        let vol = arr.reduce(0) { $0 + $1.totalVolume }
        // prefer the latest est1RM logged for the week for this lift
        let best = arr
            .filter { $0.est1RM > 0 }
            .sorted(by: { $0.date > $1.date })
            .first?.est1RM ?? 0
        return .init(lift: lift,
                     est1RM: Int(best.rounded()),
                     totalVolume: vol,
                     sessionCount: arr.count)
    }
    let total = weekEntries.reduce(0) { $0 + $1.totalVolume }
    return .init(cycle: cycle, programWeek: programWeek, totalVolume: total, lifts: lifts.sorted { $0.lift < $1.lift })
}
