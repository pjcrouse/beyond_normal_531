enum Lift: String, CaseIterable, Identifiable {
    case squat = "SQ", bench = "BP", deadlift = "DL", row = "RW"
    var id: String { rawValue }
    var label: String {
        switch self {
        case .squat: return "Squat"
        case .bench: return "Bench"
        case .deadlift: return "Deadlift"
        case .row: return "Row"
        }
    }
}
