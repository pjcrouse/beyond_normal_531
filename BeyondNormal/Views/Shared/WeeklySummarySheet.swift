import SwiftUI

struct WeeklySummarySheet: View {
    let result: WeeklySummaryResult

    /// Preferred order of lift labels, e.g. ["Squat","Bench","Deadlift","Row","Press"].
    /// If empty, falls back to alphabetical.
    let preferredOrder: [String]

    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Totals")) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Week:")
                        Text("\(formatDate(result.interval.start)) – \(formatDate(result.interval.end.addingTimeInterval(-1)))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("Total Volume: \(result.totalVolume.formatted(.number)) lb")
                            .font(.headline)
                    }
                }

                Section(header: Text("Estimated 1RMs")) {
                    if result.oneRMs.isEmpty {
                        Text("No AMRAP sets logged this week.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(sortedOneRMs.indices, id: \.self) { i in
                            let item = sortedOneRMs[i]
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(item.lift).font(.headline)
                                    Text(formatDateTime(item.date))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text("\(item.est1RM) lb")
                                    .font(.headline)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Weekly Summary")
        }
    }

    // MARK: - Sorting

    private var sortedOneRMs: [(lift: String, est1RM: Int, date: Date)] {
        // Build index map for preferred order; unknown lifts fall back to Int.max (sorted last).
        let orderIndex = Dictionary(uniqueKeysWithValues: preferredOrder.enumerated().map { ($1, $0) })
        return result.oneRMs.sorted { a, b in
            let ia = orderIndex[a.lift] ?? Int.max
            let ib = orderIndex[b.lift] ?? Int.max
            if ia != ib { return ia < ib }
            // same lift → newest first
            return a.date > b.date
        }
    }

    // MARK: - Helpers

    private func formatDate(_ d: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f.string(from: d)
    }

    private func formatDateTime(_ d: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: d)
    }
}
