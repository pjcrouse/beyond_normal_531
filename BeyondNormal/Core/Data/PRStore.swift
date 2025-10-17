import Foundation
import os.log

struct PRKey: Hashable, Codable {
    let cycle: Int
    let lift: String
}

/// Manages personal records with in-memory caching, proper error handling, and data export.
final class PRStore: ObservableObject {
    static let shared = PRStore()
    
    // MARK: - Properties
    
    @Published private(set) var bestByCycle: [PRKey: Int] = [:]   // est 1RM
    @Published private(set) var bestAllTime: [String: Int] = [:]  // lift -> est 1RM
    
    private var hasLoadedCache = false
    private let logger = Logger(subsystem: "com.beyondnormal.app", category: "PRStore")
    
    private var url: URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent("pr_store.json")
    }
    
    // MARK: - Initialization
    
    private init() {
        do {
            try load()
        } catch {
            logger.error("Failed to load PRs on init: \(error.localizedDescription)")
            // Don't crash - just start with empty data
        }
    }
    
    // MARK: - Loading
    
    /// Loads PRs from disk, using cache if already loaded.
    private func load() throws {
        // Use cache if already loaded
        if hasLoadedCache {
            return
        }
        
        guard FileManager.default.fileExists(atPath: url.path) else {
            logger.info("No PR file found - starting fresh")
            hasLoadedCache = true
            return
        }
        
        let data = try Data(contentsOf: url)
        
        do {
            let decoded = try JSONDecoder().decode(Snapshot.self, from: data)
            bestByCycle = decoded.byCycle
            bestAllTime = decoded.allTime
            hasLoadedCache = true
            logger.info("Loaded \(self.bestByCycle.count) cycle PRs, \(self.bestAllTime.count) all-time PRs")
        } catch {
            logger.error("Failed to decode PR data: \(error.localizedDescription)")
            
            // Attempt recovery: backup corrupted file and start fresh
            try backupCorruptedFile()
            bestByCycle = [:]
            bestAllTime = [:]
            hasLoadedCache = true
            
            throw PRStoreError.corruptedData(underlyingError: error)
        }
    }
    
    /// Forces a reload from disk (bypasses cache).
    func forceReload() throws {
        hasLoadedCache = false
        try load()
    }
    
    // MARK: - Saving
    
    /// Saves PRs to disk with proper error handling.
    private func persist() throws {
        let snap = Snapshot(byCycle: bestByCycle, allTime: bestAllTime)
        let data = try JSONEncoder().encode(snap)
        try data.write(to: url, options: .atomic)
        logger.info("Saved PRs to disk")
    }
    
    // MARK: - Public API
    
    /// Consider and potentially record a new PR.
    func considerPR(cycle: Int, lift: String, est1RM: Int) {
        let key = PRKey(cycle: cycle, lift: lift)
        var updated = false
        
        if (bestByCycle[key] ?? 0) < est1RM {
            bestByCycle[key] = est1RM
            updated = true
        }
        
        if (bestAllTime[lift] ?? 0) < est1RM {
            bestAllTime[lift] = est1RM
            updated = true
        }
        
        if updated {
            do {
                try persist()
                logger.info("New PR: \(lift) = \(est1RM) lb (cycle \(cycle))")
            } catch {
                logger.error("Failed to save PR: \(error.localizedDescription)")
            }
        }
    }
    
    /// Remove all PRs recorded for a specific cycle, then save.
    func resetCycle(_ cycle: Int) {
        // Drop any entries whose key.cycle matches
        let beforeCount = bestByCycle.count
        bestByCycle.keys
            .filter { $0.cycle == cycle }
            .forEach { bestByCycle.removeValue(forKey: $0) }
        
        let removed = beforeCount - bestByCycle.count
        
        if removed > 0 {
            // Rebuild the all-time cache from by-cycle values
            recomputeCachesIfNeeded()
            logger.info("Reset \(removed) PRs from cycle \(cycle)")
        }
    }
    
    /// Back-compat for call sites that used a labeled parameter.
    func resetCycle(currentCycle: Int) {
        resetCycle(currentCycle)
    }
    
    /// Rebuilds `bestAllTime` from `bestByCycle` and persists.
    func recomputeCachesIfNeeded() {
        var all: [String: Int] = [:]
        for (key, val) in bestByCycle {
            all[key.lift] = max(all[key.lift] ?? 0, val)
        }
        bestAllTime = all
        
        do {
            try persist()
            logger.info("Recomputed all-time PRs")
        } catch {
            logger.error("Failed to save after recompute: \(error.localizedDescription)")
        }
    }
    
    /// Deletes all PRs (for testing or user request).
    func deleteAll() throws {
        bestByCycle = [:]
        bestAllTime = [:]
        try persist()
        logger.warning("Deleted all PRs")
    }
    
    // MARK: - Statistics
    
    /// Returns total number of cycle-specific PRs.
    var cycleCount: Int {
        bestByCycle.count
    }
    
    /// Returns total number of all-time PRs.
    var allTimeCount: Int {
        bestAllTime.count
    }
    
    /// Returns approximate file size in bytes.
    var approximateFileSize: Int {
        guard let data = try? Data(contentsOf: url) else { return 0 }
        return data.count
    }
    
    // MARK: - Data Export
    
    /// Returns all PR data as JSON Data.
    func exportJSON() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let snap = Snapshot(byCycle: bestByCycle, allTime: bestAllTime)
        return try encoder.encode(snap)
    }
    
    /// Returns all PR data as CSV Data.
    func exportCSV() throws -> Data {
        var csv = "Type,Lift,Cycle,Value (lb)\n"
        
        // Export cycle-specific PRs
        for (key, value) in bestByCycle.sorted(by: { $0.key.cycle < $1.key.cycle }) {
            csv += "Cycle,\(key.lift),\(key.cycle),\(value)\n"
        }
        
        // Export all-time PRs
        for (lift, value) in bestAllTime.sorted(by: { $0.key < $1.key }) {
            csv += "All-Time,\(lift),-,\(value)\n"
        }
        
        guard let data = csv.data(using: .utf8) else {
            throw PRStoreError.exportFailed(reason: "Failed to encode CSV as UTF-8")
        }
        
        return data
    }
    
    // MARK: - Data Import
    
    /// Imports PRs from JSON data.
    /// - Parameter data: JSON data containing PR snapshot
    /// - Parameter replaceExisting: If true, replaces all existing PRs. If false, merges.
    func importJSON(_ data: Data, replaceExisting: Bool = false) throws {
        let imported = try JSONDecoder().decode(Snapshot.self, from: data)
        
        if replaceExisting {
            bestByCycle = imported.byCycle
            bestAllTime = imported.allTime
        } else {
            // Merge: keep higher values
            for (key, value) in imported.byCycle {
                bestByCycle[key] = max(bestByCycle[key] ?? 0, value)
            }
            for (lift, value) in imported.allTime {
                bestAllTime[lift] = max(bestAllTime[lift] ?? 0, value)
            }
        }
        
        try persist()
        logger.info("Imported PRs (replace: \(replaceExisting))")
    }
    
    // MARK: - Error Recovery
    
    /// Backs up a corrupted file for debugging.
    private func backupCorruptedFile() throws {
        let backupURL = url.deletingPathExtension()
            .appendingPathExtension("corrupted-\(Date().timeIntervalSince1970).json")
        
        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.copyItem(at: url, to: backupURL)
            logger.warning("Backed up corrupted PR file to \(backupURL.lastPathComponent)")
        }
    }
    
    // MARK: - Codable Wrapper
    
    private struct Snapshot: Codable {
        let byCycle: [PRKey: Int]
        let allTime: [String: Int]
    }
}

// MARK: - Error Types

enum PRStoreError: LocalizedError {
    case corruptedData(underlyingError: Error)
    case exportFailed(reason: String)
    
    var errorDescription: String? {
        switch self {
        case .corruptedData(let error):
            return "PR data is corrupted. A backup has been created. Error: \(error.localizedDescription)"
        case .exportFailed(let reason):
            return "Export failed: \(reason)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .corruptedData:
            return "Your PR history has been reset to prevent data loss. A backup of the corrupted file has been saved."
        case .exportFailed:
            return "Please try again or contact support if the problem persists."
        }
    }
}
