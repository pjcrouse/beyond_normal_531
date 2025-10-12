import Foundation

public enum AssistanceTag: String, CaseIterable, Codable, Identifiable, Hashable {
    // lower body
    case hamstrings, glutes, quads, calves
    // back & pull
    case lowerBack, upperBack, lats, traps, rearDelts
    // press chain
    case shoulders, triceps, biceps, chest
    // core & misc
    case abs, obliques, coreStability, grip, mobility

    public var id: String { rawValue }
    public var title: String { rawValue.localizedCapitalized }
}
