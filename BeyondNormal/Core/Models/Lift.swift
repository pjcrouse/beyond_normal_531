enum Lift: String, CaseIterable, Identifiable {
    case squat    = "SQ"
    case bench    = "BP"
    case deadlift = "DL"
    case row      = "RW"
    case press    = "PR"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .squat:    return "Squat"
        case .bench:    return "Bench"
        case .deadlift: return "Deadlift"
        case .row:      return "Row"
        case .press:    return "Press"
        }
    }
}
