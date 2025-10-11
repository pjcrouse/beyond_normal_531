import SwiftUI

struct HistorySheet: View {
    @State private var entries: [WorkoutEntry] = []
    @State private var expanded: Set<UUID> = []

    // Weekly summary presentation state
    @State private var weeklyResult: WeeklySummaryResult?

    var body: some View {
        NavigationStack {
            List {
                if entries.isEmpty {
                    ContentUnavailableView(
                        "No saved workouts yet",
                        systemImage: "tray",
                        description: Text("Tap \"Finish Workout\" after a session to log it here.")
                    )
                } else {
                    ForEach(entries.sorted(by: { $0.date > $1.date })) { e in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(e.lift).font(.headline)
                                Spacer()
                                Text(format(date: e.date))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            HStack(spacing: 16) {
                                Text("Est 1RM \(Int(e.est1RM)) lb")
                                Text("Volume \(e.totalVolume) lb")
                            }
                            .font(.subheadline)
                            .foregroundStyle(.primary)

                            HStack(spacing: 12) {
                                Text("BBB \(Int(e.bbbPct * 100))%")
                                Text("AMRAP \(e.amrapReps)")
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)

                            if let n = e.notes, !n.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                Text(n)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(expanded.contains(e.id) ? nil : 2)
                                    .padding(.top, 2)

                                Button(expanded.contains(e.id) ? "Show less" : "Show more") {
                                    if expanded.contains(e.id) { expanded.remove(e.id) } else { expanded.insert(e.id) }
                                }
                                .font(.caption)
                                .buttonStyle(.plain)
                                .padding(.top, 2)
                            }
                        }
                        .padding(.vertical, 4)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if expanded.contains(e.id) { expanded.remove(e.id) } else { expanded.insert(e.id) }
                        }
                        .contextMenu {
                            Button(role: .destructive) {
                                delete(e)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }

                            Button {
                                let formattedVolume = NumberFormatter.localizedString(
                                    from: NSNumber(value: e.totalVolume),
                                    number: .decimal
                                )
                                let formatted1RM = NumberFormatter.localizedString(
                                    from: NSNumber(value: Int(e.est1RM)),
                                    number: .decimal
                                )
                                let dateString = e.date.formatted(date: .abbreviated, time: .omitted)
                                let summary = """
                                \(e.lift): \(dateString)
                                1RM \(formatted1RM) lb • Volume \(formattedVolume) lb
                                """
                                UIPasteboard.general.string = summary
                            } label: {
                                Label("Copy summary", systemImage: "doc.on.doc")
                            }
                        }
                        .swipeActions {
                            Button(role: .destructive) {
                                delete(e)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Saved Workouts")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        entries = WorkoutStore.shared.load().sorted { $0.date > $1.date }
                    } label: { Image(systemName: "arrow.clockwise") }
                    .accessibilityLabel("Refresh")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        let interval = currentCalendarWeekInterval()
                        let result = computeWeeklySummary(for: interval, entries: WorkoutStore.shared.load())
                        weeklyResult = result
                    } label: { Image(systemName: "calendar.badge.checkmark") }
                    .accessibilityLabel("Weekly Summary")
                }
            }
            .onAppear {
                entries = WorkoutStore.shared.load().sorted { $0.date > $1.date }
            }
            .sheet(item: $weeklyResult) { r in
                WeeklySummarySheet(result: r)
                    .presentationDetents([.medium, .large])
            }
        }
    }

    // MARK: - Helpers

    private func format(date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: date)
    }

    private func delete(_ entry: WorkoutEntry) {
        WorkoutStore.shared.delete(id: entry.id)
        entries.removeAll { $0.id == entry.id }
    }
}
