import Foundation

public enum FocusArea: String, CaseIterable, Codable, Identifiable {
    case deadlift, squat, bench, press, core
    public var id: String { rawValue }
    public var title: String { rawValue.capitalized }
}
