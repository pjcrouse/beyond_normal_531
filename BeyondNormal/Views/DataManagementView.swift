import SwiftUI

/// Main data management screen - export, view, edit, and delete data.
struct DataManagementView: View {
    @StateObject private var workoutStore = WorkoutStore.shared
    @StateObject private var prStore = PRStore.shared
    
    @State private var shareURL: URL?
    
    @State private var showingDeleteConfirmation = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingSuccess = false
    @State private var successMessage = ""
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                storageSection
                exportSection
                manageDataSection
                dangerZoneSection
            }
            .navigationTitle("Data Management")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(item: $shareURL) { url in
                ActivityViewController(activityItems: [url])
            }
            .alert("Success", isPresented: $showingSuccess) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(successMessage)
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Sections
    
    private var storageSection: some View {
        let stats = DataExportHelper.getStorageStats()
        
        return Section {
            HStack {
                Label("Total Workouts", systemImage: "figure.run")
                Spacer()
                Text("\(stats.workoutCount)")
                    .foregroundStyle(.secondary)
            }
            
            HStack {
                Label("Total PRs", systemImage: "trophy.fill")
                Spacer()
                Text("\(stats.prCount)")
                    .foregroundStyle(.secondary)
            }
            
            HStack {
                Label("Total Storage", systemImage: "internaldrive")
                Spacer()
                Text(stats.formattedTotalSize)
                    .foregroundStyle(.secondary)
            }
            
        } header: {
            Text("Storage Info")
        } footer: {
            Text("Your workout history uses \(stats.formattedTotalSize) of storage.")
        }
    }
    
    private var exportSection: some View {
        Section {
            Button {
                exportAllData()
            } label: {
                Label("Export All Data (JSON)", systemImage: "square.and.arrow.up")
            }
            
            Button {
                exportWorkoutsCSV()
            } label: {
                Label("Export Workouts (CSV)", systemImage: "tablecells")
            }
            
            Button {
                exportPRsCSV()
            } label: {
                Label("Export PRs (CSV)", systemImage: "chart.line.uptrend.xyaxis")
            }
            
        } header: {
            Text("Export")
        } footer: {
            Text("Export your data to share, backup, or analyze in spreadsheet apps. JSON format preserves all data for re-import.")
        }
    }
    
    private var manageDataSection: some View {
        Section {
            NavigationLink {
                WorkoutHistoryListView()
            } label: {
                Label("View All Workouts", systemImage: "list.bullet")
            }
            
            NavigationLink {
                PRHistoryListView()
            } label: {
                Label("View All PRs", systemImage: "chart.bar.fill")
            }
            
        } header: {
            Text("Manage")
        } footer: {
            Text("View, edit, or delete individual workouts and PRs.")
        }
    }
    
    private var dangerZoneSection: some View {
        Section {
            Button(role: .destructive) {
                showingDeleteConfirmation = true
            } label: {
                Label("Delete All Data", systemImage: "trash.fill")
            }
            .confirmationDialog(
                "Delete All Data?",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete All Workouts", role: .destructive) {
                    deleteAllWorkouts()
                }
                Button("Delete All PRs", role: .destructive) {
                    deleteAllPRs()
                }
                Button("Delete Everything", role: .destructive) {
                    deleteEverything()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This action cannot be undone. Consider exporting your data first.")
            }
            
        } header: {
            Text("Danger Zone")
        } footer: {
            Text("⚠️ These actions are permanent and cannot be undone. Export your data first if you want to keep a backup.")
                .foregroundStyle(.red)
        }
    }
    
    // MARK: - Export Actions

    private func exportAllData() {
        do {
            let data = try DataExportHelper.exportAllDataJSON()
            let filename = DataExportHelper.generateFilename(prefix: "BeyondNormal_AllData", extension: "json")
            let tempURL = try DataExportHelper.createTemporaryFile(data: data, filename: filename)
            
            shareURL = tempURL
            
        } catch {
            errorMessage = "Failed to export data: \(error.localizedDescription)"
            showingError = true
        }
    }

    private func exportWorkoutsCSV() {
        do {
            let data = try DataExportHelper.exportWorkoutsCSV()
            let filename = DataExportHelper.generateFilename(prefix: "BeyondNormal_Workouts", extension: "csv")
            let tempURL = try DataExportHelper.createTemporaryFile(data: data, filename: filename)
            
            shareURL = tempURL
            
        } catch {
            errorMessage = "Failed to export workouts: \(error.localizedDescription)"
            showingError = true
        }
    }

    private func exportPRsCSV() {
        do {
            let data = try DataExportHelper.exportPRsCSV()
            let filename = DataExportHelper.generateFilename(prefix: "BeyondNormal_PRs", extension: "csv")
            let tempURL = try DataExportHelper.createTemporaryFile(data: data, filename: filename)
            
            shareURL = tempURL
            
        } catch {
            errorMessage = "Failed to export PRs: \(error.localizedDescription)"
            showingError = true
        }
    }
    
    // MARK: - Delete Actions
    
    private func deleteAllWorkouts() {
        do {
            try workoutStore.deleteAll()
            successMessage = "All workouts deleted successfully."
            showingSuccess = true
        } catch {
            errorMessage = "Failed to delete workouts: \(error.localizedDescription)"
            showingError = true
        }
    }
    
    private func deleteAllPRs() {
        do {
            try prStore.deleteAll()
            successMessage = "All PRs deleted successfully."
            showingSuccess = true
        } catch {
            errorMessage = "Failed to delete PRs: \(error.localizedDescription)"
            showingError = true
        }
    }
    
    private func deleteEverything() {
        do {
            try workoutStore.deleteAll()
            try prStore.deleteAll()
            successMessage = "All data deleted successfully."
            showingSuccess = true
        } catch {
            errorMessage = "Failed to delete data: \(error.localizedDescription)"
            showingError = true
        }
    }
}

// MARK: - Workout History List View

struct WorkoutHistoryListView: View {
    @StateObject private var store = WorkoutStore.shared
    @State private var searchText = ""
    @State private var selectedLift: String?
    
    private var filteredWorkouts: [WorkoutEntry] {
        var workouts = store.allWorkouts()
        
        // Filter by search text
        if !searchText.isEmpty {
            workouts = workouts.filter {
                $0.lift.localizedCaseInsensitiveContains(searchText) ||
                ($0.notes?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        // Filter by selected lift
        if let lift = selectedLift {
            workouts = workouts.filter { $0.lift == lift }
        }
        
        return workouts
    }
    
    private var uniqueLifts: [String] {
        let lifts = Set(store.allWorkouts().map { $0.lift })
        return lifts.sorted()
    }
    
    var body: some View {
        List {
            if !uniqueLifts.isEmpty {
                Section {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            FilterChip(
                                title: "All",
                                isSelected: selectedLift == nil
                            ) {
                                selectedLift = nil
                            }
                            
                            ForEach(uniqueLifts, id: \.self) { lift in
                                FilterChip(
                                    title: lift.capitalized,
                                    isSelected: selectedLift == lift
                                ) {
                                    selectedLift = lift
                                }
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }
            
            Section {
                if filteredWorkouts.isEmpty {
                    ContentUnavailableView(
                        "No Workouts",
                        systemImage: "figure.run",
                        description: Text("Your workout history will appear here.")
                    )
                } else {
                    ForEach(filteredWorkouts) { workout in
                        NavigationLink {
                            WorkoutDetailView(workout: workout)
                        } label: {
                            WorkoutRowView(workout: workout)
                        }
                    }
                }
            }
        }
        .navigationTitle("Workout History")
        .searchable(text: $searchText, prompt: "Search workouts")
    }
}

// MARK: - Workout Row View

struct WorkoutRowView: View {
    let workout: WorkoutEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(workout.lift.capitalized)
                    .font(.headline)
                Spacer()
                Text(workout.date, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            HStack(spacing: 12) {
                Label("\(Int(workout.est1RM)) lb", systemImage: "trophy.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Label("\(workout.totalVolume) lb", systemImage: "chart.bar.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Label("C\(workout.cycle) • W\(workout.programWeek)", systemImage: "calendar")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            if let notes = workout.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Workout Detail View

struct WorkoutDetailView: View {
    let workout: WorkoutEntry
    @StateObject private var store = WorkoutStore.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingDeleteConfirmation = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        List {
            Section("Details") {
                LabeledContent("Lift", value: workout.lift.capitalized)
                LabeledContent("Date", value: workout.date.formatted(date: .long, time: .shortened))
                LabeledContent("Estimated 1RM", value: "\(Int(workout.est1RM)) lb")
                LabeledContent("Total Volume", value: "\(workout.totalVolume) lb")
                LabeledContent("AMRAP Reps", value: "\(workout.amrapReps)")
                LabeledContent("BBB %", value: "\(Int(workout.bbbPct * 100))%")
                LabeledContent("Program Week", value: "\(workout.programWeek)")
                LabeledContent("Cycle", value: "\(workout.cycle)")
            }
            
            if let notes = workout.notes, !notes.isEmpty {
                Section("Notes") {
                    Text(notes)
                }
            }
            
            Section {
                Button(role: .destructive) {
                    showingDeleteConfirmation = true
                } label: {
                    Label("Delete Workout", systemImage: "trash")
                }
            }
        }
        .navigationTitle("Workout Details")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            "Delete this workout?",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                deleteWorkout()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This action cannot be undone.")
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func deleteWorkout() {
        do {
            try store.delete(id: workout.id)
            dismiss()
        } catch {
            errorMessage = "Failed to delete workout: \(error.localizedDescription)"
            showingError = true
        }
    }
}

// MARK: - PR History List View (Placeholder)

struct PRHistoryListView: View {
    @StateObject private var store = PRStore.shared
    
    var body: some View {
        List {
            Section("All-Time PRs") {
                if store.bestAllTime.isEmpty {
                    ContentUnavailableView(
                        "No PRs Yet",
                        systemImage: "trophy",
                        description: Text("Your personal records will appear here.")
                    )
                } else {
                    ForEach(store.bestAllTime.sorted(by: { $0.key < $1.key }), id: \.key) { lift, value in
                        HStack {
                            Text(lift.capitalized)
                            Spacer()
                            Text("\(value) lb")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            
            Section("By Cycle") {
                if store.bestByCycle.isEmpty {
                    Text("No cycle-specific PRs recorded")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(store.bestByCycle.sorted(by: { $0.key.cycle < $1.key.cycle }), id: \.key) { key, value in
                        HStack {
                            Text("\(key.lift.capitalized) (Cycle \(key.cycle))")
                            Spacer()
                            Text("\(value) lb")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("PR History")
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.accentColor : Color(.systemGray5))
                .foregroundStyle(isSelected ? .white : .primary)
                .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Activity View Controller (Native iOS Share)

struct ActivityViewController: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - URL Identifiable Extension

#if !canImport(FoundationNetworking)
extension URL: @retroactive Identifiable {
    public var id: String { absoluteString }
}
#endif

// MARK: - Preview

#Preview {
    DataManagementView()
}
