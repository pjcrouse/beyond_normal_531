import Foundation
import UIKit

/// Helper for exporting app data in various formats.
struct DataExportHelper {
    
    // MARK: - Combined Exports
    
    /// Exports all app data (workouts, PRs, awards) as a single JSON file.
    static func exportAllDataJSON() throws -> Data {
        let workouts = try WorkoutStore.shared.exportJSON()
        let prs = try PRStore.shared.exportJSON()
        
        // Decode to dictionaries for merging
        let workoutsJSON = try JSONSerialization.jsonObject(with: workouts) as? [[String: Any]] ?? []
        let prsJSON = try JSONSerialization.jsonObject(with: prs) as? [String: Any] ?? [:]
        
        let combined: [String: Any] = [
            "exportDate": ISO8601DateFormatter().string(from: Date()),
            "appVersion": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown",
            "workouts": workoutsJSON,
            "prs": prsJSON
        ]
        
        let data = try JSONSerialization.data(withJSONObject: combined, options: [.prettyPrinted, .sortedKeys])
        return data
    }
    
    /// Exports all workouts as CSV.
    static func exportWorkoutsCSV() throws -> Data {
        try WorkoutStore.shared.exportCSV()
    }
    
    /// Exports all PRs as CSV.
    static func exportPRsCSV() throws -> Data {
        try PRStore.shared.exportCSV()
    }
    
    // MARK: - File Naming
    
    /// Generates a filename with timestamp.
    static func generateFilename(prefix: String, extension ext: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmmss"
        let timestamp = formatter.string(from: Date())
        return "\(prefix)_\(timestamp).\(ext)"
    }
    
    // MARK: - Share Sheet Helpers
    
    /// Creates a temporary file and returns a share sheet-compatible URL.
    static func createTemporaryFile(data: Data, filename: String) throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(filename)
        
        // Remove if exists
        try? FileManager.default.removeItem(at: fileURL)
        
        // Write data
        try data.write(to: fileURL, options: .atomic)
        
        return fileURL
    }
    
    /// Presents a share sheet for data export.
    static func shareData(
        data: Data,
        filename: String,
        from viewController: UIViewController?,
        completion: ((Bool) -> Void)? = nil
    ) {
        do {
            let fileURL = try createTemporaryFile(data: data, filename: filename)
            
            let activityVC = UIActivityViewController(
                activityItems: [fileURL],
                applicationActivities: nil
            )
            
            // For iPad - set source view
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = viewController?.view
                popover.sourceRect = viewController?.view.bounds ?? .zero
            }
            
            activityVC.completionWithItemsHandler = { _, completed, _, _ in
                completion?(completed)
                
                // Clean up temp file after sharing
                try? FileManager.default.removeItem(at: fileURL)
            }
            
            let presenter = viewController ?? {
                guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                      let window = windowScene.windows.first(where: { $0.isKeyWindow }) else {
                    return nil
                }
                return window.rootViewController
            }()
            presenter?.present(activityVC, animated: true)
            
        } catch {
            print("Failed to share data: \(error)")
            completion?(false)
        }
    }
    
    // MARK: - Statistics
    
    /// Returns storage statistics for all data stores.
    static func getStorageStats() -> StorageStats {
        let workoutSize = WorkoutStore.shared.approximateFileSize
        let prSize = PRStore.shared.approximateFileSize
        
        return StorageStats(
            workoutCount: WorkoutStore.shared.count,
            workoutFileSize: workoutSize,
            prCount: PRStore.shared.cycleCount + PRStore.shared.allTimeCount,
            prFileSize: prSize,
            totalSize: workoutSize + prSize
        )
    }
    
    // MARK: - Data Validation
    
    /// Validates exported JSON data.
    static func validateJSON(_ data: Data) -> Bool {
        do {
            _ = try JSONSerialization.jsonObject(with: data)
            return true
        } catch {
            return false
        }
    }
}

// MARK: - Storage Stats Model

struct StorageStats {
    let workoutCount: Int
    let workoutFileSize: Int
    let prCount: Int
    let prFileSize: Int
    let totalSize: Int
    
    var totalSizeMB: Double {
        Double(totalSize) / 1_024 / 1_024
    }
    
    var workoutSizeKB: Double {
        Double(workoutFileSize) / 1_024
    }
    
    var prSizeKB: Double {
        Double(prFileSize) / 1_024
    }
    
    var formattedTotalSize: String {
        if totalSize < 1_024 {
            return "\(totalSize) bytes"
        } else if totalSize < 1_024 * 1_024 {
            return String(format: "%.1f KB", workoutSizeKB + prSizeKB)
        } else {
            return String(format: "%.2f MB", totalSizeMB)
        }
    }
}
