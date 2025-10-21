import SwiftUI
import Foundation
import UniformTypeIdentifiers
import UIKit

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

    @State private var showImporter = false
    @State private var importResultText: String?
    
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
                        let url = try AssistanceExporter.exportPackageJSON(dtos,
                                                                           liftKey: lift.label.lowercased(),
                                                                           creatorName: settings.displayAuthorName)
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
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showImporter = true
                } label: {
                    Label("Import", systemImage: "square.and.arrow.down")
                }
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
        // Import picker (.json)
        .sheet(isPresented: $showImporter) {
            JSONImportPicker { urls in
                guard let url = urls.first else { return }
                var data: Data?
                let needsAccess = url.startAccessingSecurityScopedResource()
                defer { if needsAccess { url.stopAccessingSecurityScopedResource() } }
                do {
                    data = try Data(contentsOf: url)
                } catch {
                    importResultText = "Failed to read file."
                    return
                }
                guard let data else { return }
                // Validate category must match this picker's lift
                let liftKey = lift.label.lowercased()
                let result = AssistanceImporter.`import`(data: data, mode: .requireCategoryMatch(liftKey: liftKey)) { dto in
                    // Persist via your AssistanceLibrary; map DTO → your app model
                    let equip = dto.equipment.lowercased()
                    let kind: EquipmentKind = {
                        switch equip {
                        case "bodyweight": return .bodyweight
                        case "dumbbell":   return .dumbbells
                        case "barbell":    return .barbell
                        case "machine":    return .machine
                        case "cable":      return .cable
                        default:           return .other
                        }
                    }()

                    let barOverride = (kind == .barbell) ? (dto.barWeight ?? 45) : nil

                    assistanceLibrary.add(
                        name: dto.exerciseName,
                        defaultWeight: dto.defaultWeight,
                        defaultReps: dto.defaultReps,
                        allowWeightToggle: false,
                        toggledWeight: 0,
                        usesImpliedImplements: dto.defaultWeight == 0,
                        category: lift.categoryFromLift,        // small helper below
                        areas: [],
                        tags: [],
                        authorDisplayName: dto.creatorName,
                        equipment: kind,
                        barWeightOverride: barOverride
                    )
                }

                importResultText = """
                Imported: \(result.importedCount)
                Skipped (wrong category): \(result.skippedWrongCategory)
                Failed decode: \(result.failedDecode)
                \(result.errors.isEmpty ? "" : "\nIssues:\n- " + result.errors.joined(separator: "\n- "))
                """
            }
        }
        .alert("Import Result", isPresented: Binding(get: { importResultText != nil },
                                                     set: { if !$0 { importResultText = nil } })) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(importResultText ?? "")
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

            // visible overflow button only for custom exercises
            if userIDs.contains(ex.id) {
                Menu {
                    Button {
                        exportSingle(ex)
                    } label: {
                        Label("Export JSON", systemImage: "square.and.arrow.up")
                    }

                    Button(role: .destructive) {
                        assistanceLibrary.remove(id: ex.id)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .imageScale(.medium)
                        .foregroundStyle(.secondary)
                        .padding(.leading, 4)
                }
            }

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

    private struct JSONImportPicker: UIViewControllerRepresentable {
        let onPick: ([URL]) -> Void

        func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
            let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.json])
            picker.allowsMultipleSelection = false
            picker.delegate = context.coordinator
            return picker
        }

        func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

        func makeCoordinator() -> Coordinator { Coordinator(onPick: onPick) }

        final class Coordinator: NSObject, UIDocumentPickerDelegate {
            let onPick: ([URL]) -> Void
            init(onPick: @escaping ([URL]) -> Void) { self.onPick = onPick }

            func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
                onPick(urls)
            }
            func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) { }
        }
    }
}

extension Lift {
    var categoryFromLift: ExerciseCategory {
        switch self {
        case .squat, .deadlift: return .legs
        case .bench, .press:    return .push
        case .row:              return .pull
        }
    }
    
    /// Allowed categories for the assistance picker
        var categoriesForPicker: [ExerciseCategory] {
            let base: [ExerciseCategory]
            switch self {
            case .squat:   base = [.legs]
            case .deadlift:base = [.legs, .pull]
            case .bench,
                 .press:   base = [.push]
            case .row:     base = [.pull]
            }
            // ✅ Add core globally for all lifts
            return Array(Set(base + [.core]))
        }
}
