import SwiftUI

struct ExercisePickerView: View {
    let title: String
    @Binding var selectedID: String
    let allowedCategories: [ExerciseCategory]

    @EnvironmentObject private var assistanceLibrary: AssistanceLibrary

    @State private var query: String = ""
    @State private var showAddSheet = false

    // MARK: - Data

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

    /// Apply search query
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
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    showAddSheet = true
                } label: {
                    Label("Add", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            NewAssistanceSheet(
                library: assistanceLibrary,
                preselectedCategory: presetCategory()
            )
            .presentationDetents([.medium, .large])
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

        // If the deleted one was selected, pick a safe fallback
        if ids.contains(selectedID) {
            // Refresh view of what's available now
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
}
