import SwiftUI

struct ProgramWeekSummarySheet: View {
    let result: ProgramWeekSummaryResult

    @State private var shareRequest: ShareRequest?

    var body: some View {
        NavigationStack {
            List {
                // Big header row
                VStack(alignment: .leading, spacing: 4) {
                    Text("Program Week Summary")
                        .font(.title2.bold())
                    Text("Cycle \(result.cycle) • Week \(result.programWeek)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .padding(.top, 4)

                // Totals
                Section("Overview") {
                    Text("Total Volume: \(result.totalVolume.formatted(.number)) lb")
                        .font(.headline)
                }

                // Per-lift details
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
                                    Text(s.est1RM > 0 ? "Est 1RM \(Int(s.est1RM))" : "No AMRAP")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Weekly Summary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        shareWeeklySummary(result)
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                }
            }
        }
        .sheet(item: $shareRequest) { req in
            ShareSheet(context: req.context)   // relies on ShareSheet having .weeklySummary
        }
    }

    // MARK: - Share
    private func shareWeeklySummary(_ result: ProgramWeekSummaryResult) {
        shareRequest = ShareRequest(context: .weeklySummary(result))
    }
}
