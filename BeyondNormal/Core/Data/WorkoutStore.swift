import Foundation

final class WorkoutStore {
    static let shared = WorkoutStore()
    private init() {}

    private var url: URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent("workout_history.json")
    }

    func load() -> [WorkoutEntry] {
        guard let data = try? Data(contentsOf: url) else { return [] }
        return (try? JSONDecoder().decode([WorkoutEntry].self, from: data)) ?? []
    }

    func append(_ entry: WorkoutEntry) {
        var all = load()
        all.append(entry)
        if let data = try? JSONEncoder().encode(all) {
            try? data.write(to: url, options: .atomic)
        }
    }

    func delete(id: UUID) {
        var all = load()
        all.removeAll { $0.id == id }
        if let data = try? JSONEncoder().encode(all) {
            try? data.write(to: url, options: .atomic)
        }
    }
}
