import SwiftUI

struct ProgramWeekSummarySheet: View {
    let result: ProgramWeekSummaryResult

    var body: some View {
        NavigationStack {
            List {
                Section("Cycle \(result.cycle) • Week \(result.programWeek)") {
                    Text("Total Volume: \(result.totalVolume.formatted(.number)) lb")
                        .font(.headline)
                }

                Section("Per-Lift Summary") {
                    if result.lifts.isEmpty {
                        Text("No logged workouts for this program week.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(result.lifts) { s in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(s.lift).font(.headline)
                                    Text("\(s.sessionCount) session\(s.sessionCount == 1 ? "" : "s")")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("Vol \(s.totalVolume.formatted(.number))")
                                        .font(.subheadline)
                                    Text(s.est1RM > 0 ? "Est 1RM \(s.est1RM)" : "No AMRAP")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Program Week Summary")
        }
    }
}
