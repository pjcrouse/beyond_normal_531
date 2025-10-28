import Foundation

/// Normalize, remove control chars/newlines, collapse whitespace, trim.
func sanitizedDisplayName(_ raw: String) -> String {
    // 1) Normalize (compatibility mapping handles composed forms)
    let normalized = raw.precomposedStringWithCompatibilityMapping

    // 2) Remove control characters (and newlines) in a toolchain-safe way
    let disallowed = CharacterSet.controlCharacters
        .union(.newlines)
        .union(.illegalCharacters)

    let scalars = normalized.unicodeScalars.filter { !disallowed.contains($0) }
    let stripped = String(String.UnicodeScalarView(scalars))

    // 3) Collapse any run of whitespace to a single space (regex-free for safety)
    let collapsed = stripped
        .components(separatedBy: .whitespacesAndNewlines)
        .filter { !$0.isEmpty }
        .joined(separator: " ")

    // 4) Trim ends
    return collapsed.trimmingCharacters(in: .whitespacesAndNewlines)
}

/// Grapheme-aware cap (emoji/accents count as 1).
@inline(__always)
func limitedGraphemes(_ s: String, max: Int) -> String {
    guard s.count > max else { return s }
    return String(s.prefix(max)) // String.prefix is grapheme-aware
}
