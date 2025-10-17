import Foundation

extension WorkoutStore {
    func load(in interval: DateInterval) -> [WorkoutEntry] {
        workouts.filter { interval.contains($0.date) }
    }
}

struct WeeklySummaryResult: Identifiable {
    let id = UUID()
    let interval: DateInterval
    let totalVolume: Int
    let oneRMs: [(lift: String, est1RM: Int, date: Date)]
}

func computeWeeklySummary(for interval: DateInterval, entries: [WorkoutEntry]) -> WeeklySummaryResult {
    let weekEntries = entries.filter { interval.contains($0.date) }
    let total = weekEntries.reduce(0) { $0 + $1.totalVolume }
    let oneRMs = weekEntries
        .filter { $0.est1RM > 0 }
        .map { (lift: $0.lift, est1RM: Int($0.est1RM.rounded()), date: $0.date) }
        .sorted { $0.date > $1.date }

    return WeeklySummaryResult(interval: interval, totalVolume: total, oneRMs: oneRMs)
}

func currentCalendarWeekInterval() -> DateInterval {
    let cal = Calendar.current
    let today = Date()
    if let interval = cal.dateInterval(of: .weekOfYear, for: today) {
        return interval
    }
    let start = cal.startOfDay(for: today)
    return DateInterval(start: start, end: cal.date(byAdding: .day, value: 7, to: start)!)
}

func computeProgramWeekSummary(
    programWeek: Int,
    cycle: Int,
    entries: [WorkoutEntry]
) -> WeeklySummaryResult {
    let weekEntries = entries.filter { $0.programWeek == programWeek && $0.cycle == cycle }

    let total = weekEntries.reduce(0) { $0 + $1.totalVolume }
    let oneRMs = weekEntries
        .filter { $0.est1RM > 0 }
        .map { (lift: $0.lift, est1RM: Int($0.est1RM.rounded()), date: $0.date) }
        .sorted { $0.date > $1.date }

    let start = weekEntries.map(\.date).min() ?? Date()
    let end   = weekEntries.map(\.date).max()?.addingTimeInterval(1) ?? Date()
    let interval = DateInterval(start: start, end: end)

    return WeeklySummaryResult(interval: interval, totalVolume: total, oneRMs: oneRMs)
}
