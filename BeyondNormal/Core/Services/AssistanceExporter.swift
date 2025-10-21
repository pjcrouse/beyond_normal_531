import Foundation

/// Writes AssistanceExerciseExport JSON files and returns their file URLs.
enum AssistanceExporter {

    // MARK: - Public API

    /// Exports a *package* (array) as ONE JSON file and returns its URL.
    static func exportPackageJSON(_ dtos: [AssistanceExerciseExport],
                                  liftKey: String,
                                  creatorName: String? = nil) throws -> URL {
        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        let data = try enc.encode(dtos)

        // Build a friendly name: App-Assistance-<lift>-<creator>-<N>items-<stamp>.json
        let app = appShortName()
        let base = safeFileName(components: [
            app, "Assistance", liftKey.lowercased(),
            (creatorName?.isEmpty == false ? creatorName! : nil),
            "\(dtos.count)items"
        ])
        let url = makeTempURL(fileName: base, ext: "json")
        try data.write(to: url, options: .atomic)
        return url
    }

    /// Exports one DTO to a temp file and returns its URL.
    @discardableResult
    static func exportJSON(_ dto: AssistanceExerciseExport,
                           creatorName: String? = nil) throws -> URL {
        let data = try makeJSONData(dto)

        // <Exercise>-<category>-<creator>-<stamp>.json
        let base = safeFileName(components: [
            dto.exerciseName,
            dto.category.lowercased(),
            (creatorName?.isEmpty == false ? creatorName! : nil)
        ])
        let url = makeTempURL(fileName: base, ext: "json")
        try data.write(to: url, options: .atomic)
        return url
    }

    /// Exports many DTOs as individual files and returns their URLs. Any failure is skipped.
    static func exportMany(_ dtos: [AssistanceExerciseExport],
                           creatorName: String? = nil) -> [URL] {
        var urls: [URL] = []
        for dto in dtos {
            do {
                let data = try makeJSONData(dto)
                let base = safeFileName(components: [
                    dto.exerciseName,
                    dto.category.lowercased(),
                    (creatorName?.isEmpty == false ? creatorName! : nil)
                ])
                let url = makeTempURL(fileName: base, ext: "json")
                try data.write(to: url, options: .atomic)
                urls.append(url)
            } catch {
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
        // Add a compact timestamp to avoid collisions
        let stamp = timestamp()
        let full = capped("\(fileName)-\(stamp)", maxLen: 80) + ".\(ext)"
        return FileManager.default.temporaryDirectory.appendingPathComponent(full, isDirectory: false)
    }

    // MARK: - Filename helpers

    /// Build a safe base name from multiple parts, skipping nil/empty parts.
    private static func safeFileName(components: [String?]) -> String {
        let joined = components
            .compactMap { $0 }
            .map { sanitizeFileComponent($0) }
            .filter { !$0.isEmpty }
            .joined(separator: "-")

        // Collapse consecutive dashes, trim, and cap length
        let collapsed = joined.replacingOccurrences(of: "-{2,}", with: "-", options: .regularExpression)
        return capped(collapsed.trimmingCharacters(in: CharacterSet(charactersIn: "-")), maxLen: 64)
    }

    /// Sanitize a single component: strip diacritics/emoji, keep A–Z a–z 0–9 _ - and space.
    private static func sanitizeFileComponent(_ s: String) -> String {
        // 1) Fold diacritics (é → e)
        let folded = s.folding(options: [.diacriticInsensitive, .widthInsensitive, .caseInsensitive], locale: .current)

        // 2) Allowlist chars; convert spaces to underscores
        let allowed = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_ ")
        let cleanedScalars = folded.unicodeScalars.map { allowed.contains($0) ? Character($0) : Character(" ") }
        let cleaned = String(cleanedScalars)

        // 3) spaces → underscores, collapse repeats
        var underscored = cleaned.replacingOccurrences(of: " ", with: "_")
        underscored = underscored.replacingOccurrences(of: "_{2,}", with: "_", options: .regularExpression)

        // 4) Trim underscores/dashes
        let trimmed = underscored.trimmingCharacters(in: CharacterSet(charactersIn: "_-"))
        return trimmed
    }

    /// Cap length (so Finder / Files never freak out on long names)
    private static func capped(_ s: String, maxLen: Int) -> String {
        guard s.count > maxLen else { return s }
        let endIdx = s.index(s.startIndex, offsetBy: maxLen)
        return String(s[..<endIdx])
    }

    // MARK: - Small utilities

    private static func timestamp() -> String {
        // yyyyMMdd-HHmmss in local time
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyyMMdd-HHmmss"
        return f.string(from: Date())
    }

    private static func appShortName() -> String {
        // Try CFBundleDisplayName → CFBundleName → fallback
        let b = Bundle.main
        return (b.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String)
        ?? (b.object(forInfoDictionaryKey: "CFBundleName") as? String)
        ?? "BeyondNormal"
    }
}
