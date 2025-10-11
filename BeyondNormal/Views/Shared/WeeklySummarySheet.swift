import SwiftUI

struct WeeklySummarySheet: View {
    let result: WeeklySummaryResult

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
                        ForEach(result.oneRMs.indices, id: \.self) { i in
                            let item = result.oneRMs[i]
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
