import Foundation

struct PRKey: Hashable, Codable {
    let cycle: Int
    let lift: String
}

final class PRStore {
    static let shared = PRStore()
    private init() { load() }

    private var url: URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent("pr_store.json")
    }

    private(set) var bestByCycle: [PRKey: Int] = [:]   // est 1RM
    private(set) var bestAllTime: [String: Int] = [:]  // lift -> est 1RM

    private func load() {
        guard let data = try? Data(contentsOf: url) else { return }
        if let decoded = try? JSONDecoder().decode(Snapshot.self, from: data) {
            bestByCycle = decoded.byCycle
            bestAllTime = decoded.allTime
        }
    }

    private func persist() {
        let snap = Snapshot(byCycle: bestByCycle, allTime: bestAllTime)
        if let data = try? JSONEncoder().encode(snap) {
            try? data.write(to: url, options: .atomic)
        }
    }

    func considerPR(cycle: Int, lift: String, est1RM: Int) {
        let key = PRKey(cycle: cycle, lift: lift)
        if (bestByCycle[key] ?? 0) < est1RM { bestByCycle[key] = est1RM }
        if (bestAllTime[lift] ?? 0) < est1RM { bestAllTime[lift] = est1RM }
        persist()
    }

    // Codable wrapper for dictionaries with non-String keys
    private struct Snapshot: Codable {
        let byCycle: [PRKey: Int]
        let allTime: [String: Int]
    }
}
