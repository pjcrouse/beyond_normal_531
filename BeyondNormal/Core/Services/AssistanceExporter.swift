import Foundation

/// Writes AssistanceExerciseExport JSON files and returns their file URLs.
enum AssistanceExporter {

    static func exportPackageJSON(_ dtos: [AssistanceExerciseExport],
                                  liftKey: String) throws -> URL {
        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        let data = try enc.encode(dtos)

        let url = makeTempURL(
            fileName: safeFileName("BeyondNormal_Assistance_\(liftKey)"),
            ext: "json"
        )
        try data.write(to: url, options: .atomic)
        return url
    }
    
    /// Exports one DTO to a temp file and returns its URL.
    @discardableResult
    static func exportJSON(_ dto: AssistanceExerciseExport) throws -> URL {
        let data = try makeJSONData(dto)
        let url  = makeTempURL(
            fileName: safeFileName("\(dto.exerciseName)_\(dto.category)"),
            ext: "json"
        )
        try data.write(to: url, options: .atomic)
        return url
    }

    /// Exports many DTOs and returns all file URLs. Any individual failure is skipped.
    static func exportMany(_ dtos: [AssistanceExerciseExport]) -> [URL] {
        var urls: [URL] = []
        for dto in dtos {
            do {
                let data = try makeJSONData(dto)
                let url  = makeTempURL(
                    fileName: safeFileName("\(dto.exerciseName)_\(dto.category)"),
                    ext: "json"
                )
                try data.write(to: url, options: .atomic)
                urls.append(url)
            } catch {
                // Skip failed item; optionally log in DEBUG
                #if DEBUG
                print("AssistanceExporter: failed to export \(dto.exerciseName): \(error)")
                #endif
            }
        }
        return urls
    }

    // MARK: - Internals

    private static func makeJSONData(_ dto: AssistanceExerciseExport) throws -> Data {
        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return try enc.encode(dto)
    }

    private static func makeTempURL(fileName: String, ext: String) -> URL {
        // Put a timestamp on file name to avoid collisions
        let stamp = isoTimestamp()
        let fullName = "\(fileName)_\(stamp).\(ext)"
        return FileManager.default.temporaryDirectory.appendingPathComponent(fullName, isDirectory: false)
    }

    private static func safeFileName(_ s: String) -> String {
        let invalid = CharacterSet(charactersIn: "/\\?%*|\"<>:")
        let cleaned = s.components(separatedBy: invalid).joined(separator: "_")
        return cleaned.replacingOccurrences(of: " ", with: "_")
    }

    private static func isoTimestamp() -> String {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withColonSeparatorInTime, .withDashSeparatorInDate]
        return f.string(from: Date())
            .replacingOccurrences(of: ":", with: "")
            .replacingOccurrences(of: "-", with: "")
    }
}
