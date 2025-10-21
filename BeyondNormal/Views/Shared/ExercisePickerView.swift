import SwiftUI
import Foundation

struct ExercisePickerView: View {
    // MARK: Inputs
    let title: String
    @Binding var selectedID: String
    let allowedCategories: [ExerciseCategory]
    let lift: Lift                                 // which main lift this picker is for

    // MARK: Env / State
    @EnvironmentObject private var assistanceLibrary: AssistanceLibrary
    @EnvironmentObject private var settings: ProgramSettings

    @State private var query: String = ""
    @State private var showAddSheet = false

    // Export state
    @State private var shareURL: URL?              // file to hand to ShareSheet(context:)

    // MARK: Derived data

    /// All exercises (built-in + user) that match allowed categories
    private var all: [AssistanceExercise] {
        assistanceLibrary.all
            .filter { allowedCategories.contains($0.category) }
    }

    /// IDs of user-created exercises
    private var userIDs: Set<String> {
        Set(assistanceLibrary.userCreated.map { $0.id })
    }

    /// Split into custom vs built-in
    private var custom: [AssistanceExercise] {
        filtered(from: all.filter { userIDs.contains($0.id) })
    }
    private var builtIns: [AssistanceExercise] {
        filtered(from: all.filter { !userIDs.contains($0.id) })
    }

    /// Apply search query and sort
    private func filtered(from list: [AssistanceExercise]) -> [AssistanceExercise] {
        let base = list.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        guard !query.isEmpty else { return base }
        return base.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    // MARK: - Body

    var body: some View {
        List {
            if !custom.isEmpty {
                Section("Your Custom") {
                    ForEach(custom) { ex in
                        row(ex)
                            // Swipe to export (single)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button {
                                    exportSingle(ex)
                                } label: {
                                    Label("Export", systemImage: "arrow.down.doc")
                                }
                                .tint(.orange)
                            }
                            // Optional long-press alternative
                            .contextMenu {
                                Button {
                                    exportSingle(ex)
                                } label: {
                                    Label("Export JSON", systemImage: "square.and.arrow.up")
                                }
                            }
                    }
                    .onDelete(perform: deleteCustom)
                }
            }

            Section("Available Exercises") {
                if builtIns.isEmpty && custom.isEmpty {
                    ContentUnavailableView(
                        "No matches",
                        systemImage: "magnifyingglass",
                        description: Text("Try a different search term.")
                    )
                } else {
                    ForEach(builtIns) { ex in
                        row(ex)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(title)
        .searchable(text: $query, placement: .navigationBarDrawer)
        .toolbar {
            // Add new custom exercise
            ToolbarItem(placement: .confirmationAction) {
                Button { showAddSheet = true } label: {
                    Label("Add", systemImage: "plus")
                }
            }
            // Export all custom exercises for this lift as ONE JSON file (AirDrop-compatible)
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    let dtos = custom.map { ex in
                        AssistanceExerciseExport.fromAppModel(
                            exercise: ex,
                            category: lift,
                            creatorName: settings.displayAuthorName,
                            creatorID: settings.authorID// <- use your resolver
                        )
                    }
                    do {
                        let liftKey = lift.label.lowercased()
                        let url = try AssistanceExporter.exportPackageJSON(dtos, liftKey: liftKey)
                        shareURL = url
                    } catch {
                        #if DEBUG
                        print("Export All failed: \(error)")
                        #endif
                    }
                } label: {
                    Label("Export All", systemImage: "square.and.arrow.up.on.square")
                }
                .disabled(custom.isEmpty)
            }
        }
        // Add-new sheet
        .sheet(isPresented: $showAddSheet) {
            NewAssistanceSheet(
                library: assistanceLibrary,
                preselectedCategory: presetCategory()
            )
            .presentationDetents([.medium, .large])
        }
        // Single-file share via your global ShareSheet(context:)
        .sheet(item: Binding(
            get: { shareURL.map(IdentifiedURL.init(url:)) },
            set: { shareURL = $0?.url }
        )) { wrapper in
            ShareSheet(context: .fileURL(wrapper.url))
        }
    }

    // MARK: - Row

    @ViewBuilder
    private func row(_ ex: AssistanceExercise) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(ex.name).font(.body)
                Text(ex.category.rawValue.capitalized)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if selectedID == ex.id {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.tint)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { selectedID = ex.id }
    }

    // MARK: - Delete

    private func deleteCustom(at offsets: IndexSet) {
        // Take a snapshot so indices are stable
        let items = custom
        let ids = offsets.compactMap { idx in
            items.indices.contains(idx) ? items[idx].id : nil
        }

        // Remove from library
        ids.forEach { assistanceLibrary.remove(id: $0) }

        // If a deleted item was selected, pick a safe fallback
        if ids.contains(selectedID) {
            let newAll = assistanceLibrary.all
                .filter { allowedCategories.contains($0.category) }
                .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            if let first = newAll.first {
                selectedID = first.id
            }
        }
    }

    // MARK: - Helpers

    /// If exactly one category is allowed, use it as the preselected category; otherwise nil.
    private func presetCategory() -> ExerciseCategory? {
        allowedCategories.count == 1 ? allowedCategories.first : nil
    }

    // MARK: - Export helpers

    private func exportSingle(_ ex: AssistanceExercise) {
        let dto = AssistanceExerciseExport.fromAppModel(
            exercise: ex,
            category: lift,
            creatorName: settings.displayAuthorName,
            creatorID: settings.authorID
        )
        shareURL = try? AssistanceExporter.exportJSON(dto)
    }

    // Wrapper to use .sheet(item:)
    private struct IdentifiedURL: Identifiable {
        let url: URL
        var id: URL { url }
    }
}
