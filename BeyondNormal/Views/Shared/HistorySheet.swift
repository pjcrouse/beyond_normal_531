import SwiftUI

struct HistorySheet: View {
    // ✅ Pass in the program’s active lifts, in UI order
    let availableLifts: [Lift]
    let currentProgramWeek: Int
    let currentCycle: Int
    
    @State private var entries: [WorkoutEntry] = []
    @State private var expanded: Set<UUID> = []
    
    // ✅ New: filter state (nil = All)
    @State private var selectedFilter: Lift? = nil
    
    @State private var pwResult: ProgramWeekSummaryResult?
    
    @State private var activeShare: ShareRequest? = nil
    
    @State private var showDeleteError = false
    @State private var deleteErrorMessage = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 8) {
                
                // Filter bar
                filterBar
                
                List {
                    if sortedFilteredEntries.isEmpty {
                        ContentUnavailableView(
                            "No saved workouts\(selectedFilterTextSuffix)",
                            systemImage: "tray",
                            description: Text("Tap \"Finish Workout\" after a session to log it here.")
                        )
                    } else {
                        ForEach(sortedFilteredEntries) { e in    // ✅ simpler, pre-sorted
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
                                        toggleExpanded(e.id)
                                    }
                                    .font(.caption)
                                    .buttonStyle(.plain)
                                    .padding(.top, 2)
                                }
                            }
                            .padding(.vertical, 4)
                            .contentShape(Rectangle())
                            .onTapGesture { toggleExpanded(e.id) }
                            .contextMenu {
                                Button(role: .destructive) {
                                    delete(e)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                
                                Button {
                                    shareSummary(for: e)
                                } label: {
                                    Label("Share summary", systemImage: "square.and.arrow.up")
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
            }
            .navigationTitle("Saved Workouts")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        entries = WorkoutStore.shared.workouts.sorted { $0.date > $1.date }
                    } label: { Image(systemName: "arrow.clockwise") }
                        .accessibilityLabel("Refresh")
                }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            let result = computeProgramWeekSummary(
                                cycle: currentCycle,
                                programWeek: currentProgramWeek,
                                entries: WorkoutStore.shared.workouts
                            )
                            pwResult = result
                        } label: { Image(systemName: "calendar.badge.checkmark") } // looks like “week”
                            .accessibilityLabel("Program Week Summary")
                    }
            }
            .onAppear {
                entries = WorkoutStore.shared.workouts.sorted { $0.date > $1.date }
            }
            .sheet(item: $pwResult) { r in
                ProgramWeekSummarySheet(result: r)
                    .presentationDetents([.medium, .large])
            }
            .sheet(item: $activeShare) { req in
                ShareSheet(context: req.context)
            }
            .alert("Error", isPresented: $showDeleteError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(deleteErrorMessage)
            }
        }
    }
    
    // Pre-sorted data to keep the view builder simple (and fast to type-check)
    private var sortedFilteredEntries: [WorkoutEntry] {
        filteredEntries.sorted { $0.date > $1.date }
    }
    
    // MARK: - Filter UI
    
    private var filterBar: some View {
        // Builds ["All", "Squat", "Bench", ...] from availableLifts
        let _: [Lift?] = [nil] + availableLifts
        
        return Picker("Filter", selection: $selectedFilter) {
            Text("All").tag(Optional<Lift>.none)
            ForEach(availableLifts) { lift in
                Text(lift.label).tag(Optional<Lift>(lift))
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    private var filteredEntries: [WorkoutEntry] {
        guard let f = selectedFilter else { return entries }
        // Compare against stored label to avoid enum parsing
        return entries.filter { $0.lift == f.label }
    }
    
    private var selectedFilterTextSuffix: String {
        guard let f = selectedFilter else { return "" }
        return " for \(f.label)"
    }
    
    // MARK: - Helpers
    
    private func format(date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: date)
    }
    
    private func toggleExpanded(_ id: UUID) {
        if expanded.contains(id) { expanded.remove(id) } else { expanded.insert(id) }
    }
    
    private func delete(_ entry: WorkoutEntry) {
        do {
            try WorkoutStore.shared.delete(id: entry.id)
            entries.removeAll { $0.id == entry.id }
        } catch {
            print("⚠️ Failed to delete workout: \(error.localizedDescription)")
            deleteErrorMessage = "Failed to delete workout: \(error.localizedDescription)"
            showDeleteError = true
        }
    }
    
    // MARK: - Share helper
    private func shareSummary(for e: WorkoutEntry) {
        let formattedVolume = NumberFormatter.localizedString(
            from: NSNumber(value: e.totalVolume), number: .decimal
        )
        let formatted1RM = NumberFormatter.localizedString(
            from: NSNumber(value: Int(e.est1RM)), number: .decimal
        )
        let dateString = e.date.formatted(date: .abbreviated, time: .omitted)
        
        let notes = (e.notes ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let notesLine = notes.isEmpty ? "" : "\n\(notes)"
        
        let summaryText = """
        \(e.lift): \(dateString)
        1RM \(formatted1RM) lb • Volume \(formattedVolume) lb\(notesLine)
        """
        
        print("DEBUG SHARE SUMMARY:\n\(summaryText)")
        
        // ✅ Capture the final payload in the item that drives the sheet
        activeShare = ShareRequest(context: .summary(summaryText))
    }
}
