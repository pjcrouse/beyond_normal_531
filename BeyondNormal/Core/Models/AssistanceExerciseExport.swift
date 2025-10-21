import Foundation

/// JSON payload we export for a single assistance exercise
public struct AssistanceExerciseExport: Codable {
    public let schemaVersion: Int
    public let creatorName: String
    public let creatorID: String            // UUID string for attribution
    public let exerciseName: String

    /// One of the 5 main lifts ("squat","bench","deadlift","row","press")
    public let category: String

    public let defaultReps: Int
    public let defaultWeight: Double

    /// One of: "bodyweight","dumbbell","barbell","machine","cable","other"
    public let equipment: String

    /// Present only when `equipment == "barbell"`
    public let barWeight: Double?

    // MARK: - Factory from your in-app models
    static func fromAppModel(
        exercise: AssistanceExercise,
        category: Lift,
        creatorName: String,
        creatorID: UUID
    ) -> AssistanceExerciseExport {
        AssistanceExerciseExport(
            schemaVersion: 1,
            creatorName: creatorName,
            creatorID: creatorID.uuidString,             // ← use the param, not the type name
            exerciseName: exercise.name,
            category: category.exportKey,
            defaultReps: exercise.defaultReps,
            defaultWeight: exercise.defaultWeight,
            equipment: exercise.equipment.exportKey,
            barWeight: exercise.equipment == .barbell
                ? (exercise.barWeightOverride ?? 45)
                : nil
        )
    }
}

// MARK: - Small mapping helpers

private extension Lift {
    var exportKey: String {
        switch self {
        case .squat: return "squat"
        case .bench: return "bench"
        case .deadlift: return "deadlift"
        case .row: return "row"
        case .press: return "press"
        }
    }
}

private extension EquipmentKind {
    var exportKey: String {
        switch self {
        case .bodyweight: return "bodyweight"
        case .dumbbells:  return "dumbbell"
        case .barbell:    return "barbell"
        case .machine:    return "machine"
        case .cable:      return "cable"
        case .other:      return "other"
        }
    }
}
