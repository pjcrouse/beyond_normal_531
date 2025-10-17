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
extension Lift {
    var isUpperBody: Bool {
        switch self {
        case .bench, .row, .press: return true
        case .squat, .deadlift:    return false
        }
    }
}
extension Lift {
    var isLowerBody: Bool { !isUpperBody }
}
extension Lift {
    var frontImageAssetName: String {
        switch self {
        case .squat:    return "squat_medal_front"
        case .deadlift: return "deadlift_medal_front"
        case .bench:    return "bench_medal_front"
        case .press:    return "press_medal_front"
        case .row:      return "row_medal_front"
        }
    }
    var prBackImageAssetName: String {
        "medal_back_base"
    }
}
