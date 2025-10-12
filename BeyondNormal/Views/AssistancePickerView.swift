import SwiftUI

struct AssistancePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var library: AssistanceLibrary

    let area: FocusArea
    @Binding var selectedID: String

    // Local state
    @State private var showAddSheet = false

    // All exercises for this area
    private var all: [AssistanceExercise] { library.forArea(area) }
    // Split into custom vs built-in (by id membership in userCreated)
    private var custom: [AssistanceExercise] {
        let ids = Set(library.userCreated.map { $0.id })
        return all.filter { ids.contains($0.id) }
    }
    private var builtIns: [AssistanceExercise] {
        let ids = Set(library.userCreated.map { $0.id })
        return all.filter { !ids.contains($0.id) }
    }

    var body: some View {
        NavigationStack {
            List {
                if !custom.isEmpty {
                    Section("Your Custom") {
                        ForEach(custom) { ex in
                            row(ex)
                        }
                        // Native swipe-to-delete for custom items only
                        .onDelete(perform: deleteCustom)
                    }
                }

                Section("Available Exercises") {
                    ForEach(builtIns) { ex in
                        row(ex)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("\(area.title) Assistance")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button { showAddSheet = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                NewAssistanceSheet(
                    library: library,
                    preselectedCategory: presetCategory(for: area)
                )
            }
        }
    }

    // MARK: - Row

    @ViewBuilder
    private func row(_ ex: AssistanceExercise) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(ex.name)
                    .fontWeight(ex.id == selectedID ? .semibold : .regular)
                Text(ex.category.rawValue.capitalized)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if ex.id == selectedID {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.tint)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            selectedID = ex.id
            dismiss()
        }
    }

    // MARK: - Delete

    private func deleteCustom(at offsets: IndexSet) {
        // Work off the current snapshot of custom list
        let items = custom
        let idsToDelete = offsets.compactMap { idx -> String? in
            guard items.indices.contains(idx) else { return nil }
            return items[idx].id
        }

        // Remove from library
        idsToDelete.forEach { library.remove(id: $0) }

        // If the selected item was removed, pick a safe fallback from the new list
        if idsToDelete.contains(selectedID) {
            let newAll = library.forArea(area)
            if let first = newAll.first {
                selectedID = first.id
            }
        }
    }

    // MARK: - Helpers

    /// Reasonable default category for the sheet; nil if ambiguous so the user chooses.
    private func presetCategory(for area: FocusArea) -> ExerciseCategory? {
        let t = area.title.lowercased()
        if t.contains("bench")     { return .push }
        if t.contains("row") || t.contains("back") { return .pull }
        if t.contains("squat")     { return .legs }
        if t.contains("deadlift")  { return nil }  // legs or core—let the user pick
        if t.contains("core")      { return .core }
        return nil
    }
}
