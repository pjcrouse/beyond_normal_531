import Foundation
import SwiftUI

@MainActor
final class AssistanceLibrary: ObservableObject {
    static let shared = AssistanceLibrary()

    // Built-ins come from your existing static catalog
    // (They won't have areas/tags yet — that's fine. We treat empty areas as "show everywhere".)
    private let builtIns: [AssistanceExercise] = AssistanceExercise.catalog

    // User-created items (persisted)
    @Published private(set) var userCreated: [AssistanceExercise] = []

    // MARK: - Init / Load
    init() {
        load()
    }

    // MARK: - Public API

    /// All exercises (built-ins + user-created)
    var all: [AssistanceExercise] { builtIns + userCreated }

    /// Filter for a given focus area and optional tag set.
    /// NOTE: If an exercise has no areas (empty), we treat it as "visible everywhere"
    /// so your built-ins still appear before you seed areas/tags.
    func forArea(_ area: FocusArea, filteredBy tags: Set<AssistanceTag> = []) -> [AssistanceExercise] {
        let base = all.filter { ex in
            ex.areas.isEmpty || ex.areas.contains(area)
        }
        let filtered = tags.isEmpty ? base : base.filter { ex in
            ex.tags.isEmpty == false && ex.tags.intersection(tags).isEmpty == false
        }
        return filtered.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    /// Create a new user-defined assistance exercise.
    func add(name: String,
             defaultWeight: Double,
             defaultReps: Int,
             allowWeightToggle: Bool,
             toggledWeight: Double,
             usesImpliedImplements: Bool,
             category: ExerciseCategory,
             areas: Set<FocusArea>,
             tags: Set<AssistanceTag>,
             authorDisplayName: String?,
             equipment: EquipmentKind = .bodyweight,
             barWeightOverride: Double? = nil) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isDuplicate(name: trimmed, category: category) else { return }

        let new = AssistanceExercise(
            id: UUID().uuidString,
            name: trimmed,
            defaultWeight: defaultWeight,
            defaultReps: defaultReps,
            allowWeightToggle: allowWeightToggle,
            toggledWeight: toggledWeight,
            usesImpliedImplements: usesImpliedImplements,
            category: category,
            areas: areas,
            tags: tags,
            authorDisplayName: authorDisplayName,
            equipment: equipment,
            barWeightOverride: barWeightOverride
        )
        userCreated.append(new)
        save()
    }

    func rename(id: String, to newName: String) {
        guard let i = userCreated.firstIndex(where: { $0.id == id }) else { return }
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              !isDuplicate(name: trimmed, category: userCreated[i].category, excluding: id) else { return }
        userCreated[i].name = trimmed
        save()
    }

    func updateMeta(id: String,
                    defaultWeight: Double? = nil,
                    defaultReps: Int? = nil,
                    allowWeightToggle: Bool? = nil,
                    toggledWeight: Double? = nil,
                    usesImpliedImplements: Bool? = nil,
                    category: ExerciseCategory? = nil,
                    areas: Set<FocusArea>? = nil,
                    tags: Set<AssistanceTag>? = nil) {
        guard let i = userCreated.firstIndex(where: { $0.id == id }) else { return }
        if let v = defaultWeight { userCreated[i].defaultWeight = v }
        if let v = defaultReps { userCreated[i].defaultReps = v }
        if let v = allowWeightToggle { userCreated[i].allowWeightToggle = v }
        if let v = toggledWeight { userCreated[i].toggledWeight = v }
        if let v = usesImpliedImplements { userCreated[i].usesImpliedImplements = v }
        if let v = category { userCreated[i].category = v }
        if let v = areas { userCreated[i].areas = v }
        if let v = tags { userCreated[i].tags = v }
        save()
    }

    func remove(id: String) {
        userCreated.removeAll { $0.id == id }
        save()
    }

    // MARK: - Dedupe

    private func isDuplicate(name: String, category: ExerciseCategory, excluding id: String? = nil) -> Bool {
        let key = normalize(name) + "::" + category.rawValue.lowercased()
        let match = all.first { normalize($0.name) + "::" + $0.category.rawValue.lowercased() == key }
        if let id { return match?.id != id && match != nil }
        return match != nil
    }

    private func normalize(_ s: String) -> String {
        s.trimmingCharacters(in: .whitespacesAndNewlines)
         .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
         .lowercased()
    }

    // MARK: - Persistence

    private let filename = "custom_assistance_v1.json"

    private func url() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(filename)
    }

    private func save() {
        let data = try? JSONEncoder().encode(userCreated)
        try? data?.write(to: url(), options: [.atomic])
    }

    private func load() {
        guard let data = try? Data(contentsOf: url()) else { return }
        if let decoded = try? JSONDecoder().decode([AssistanceExercise].self, from: data) {
            userCreated = decoded
        }
    }
}

// MARK: - Convenience
extension AssistanceLibrary {
    var allExercises: [AssistanceExercise] { all }
}
