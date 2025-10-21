import Foundation

/// Import Result
public struct AssistanceImportResult {
    public let importedCount: Int
    public let skippedWrongCategory: Int
    public let failedDecode: Int
    public let errors: [String]
}

enum AssistanceImportError: Error {
    case badData
    case decodeFailed
}

public enum AssistanceImportMode {
    /// Require that every DTO's `category` matches the picker context (recommended)
    case requireCategoryMatch(liftKey: String)
    /// Allow any category; the picker/lift determines where it will be used in-app
    case acceptAny
}

public struct AssistanceImporter {

    /// Accepts raw data that may be a single object or an array of objects.
    /// - Parameters:
    ///   - data: JSON data exported by BN (schema v1)
    ///   - mode: category validation behavior
    ///   - save: closure called for each decoded DTO; use it to persist into your library
    public static func `import`(
        data: Data,
        mode: AssistanceImportMode,
        save: (_ dto: AssistanceExerciseExport) -> Void
    ) -> AssistanceImportResult {

        var decoded: [AssistanceExerciseExport] = []
        var failedDecode = 0
        var errors: [String] = []

        // Try array first, then single object
        do {
            decoded = try JSONDecoder().decode([AssistanceExerciseExport].self, from: data)
        } catch {
            do {
                let single = try JSONDecoder().decode(AssistanceExerciseExport.self, from: data)
                decoded = [single]
            } catch {
                failedDecode = 1
                errors.append("Could not decode JSON as AssistanceExerciseExport or [AssistanceExerciseExport].")
                return AssistanceImportResult(importedCount: 0, skippedWrongCategory: 0, failedDecode: failedDecode, errors: errors)
            }
        }

        var imported = 0
        var skippedWrongCategory = 0

        for dto in decoded {
            // Lock schema version (we only accept v1 right now)
            guard dto.schemaVersion == 1 else {
                errors.append("Unsupported schemaVersion \(dto.schemaVersion) for \(dto.exerciseName).")
                continue
            }

            // Validate category if required
            switch mode {
            case .requireCategoryMatch(let liftKey):
                if dto.category.lowercased() != liftKey {
                    skippedWrongCategory += 1
                    continue
                }
            case .acceptAny:
                break
            }

            // If we got here, we accept and "save"
            save(dto)
            imported += 1
        }

        return AssistanceImportResult(
            importedCount: imported,
            skippedWrongCategory: skippedWrongCategory,
            failedDecode: failedDecode,
            errors: errors
        )
    }
}
