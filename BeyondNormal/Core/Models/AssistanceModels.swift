import Foundation

enum ExerciseCategory: String, Codable, CaseIterable {
    case push, pull, legs, core
}

struct AssistanceExercise: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let defaultWeight: Double        // 0 = bodyweight
    let defaultReps: Int
    let allowWeightToggle: Bool      // e.g. dips, split squats with DBs
    let toggledWeight: Double        // default DB weight when toggled
    let usesImpliedImplements: Bool  // cosmetic label (EZ bar, machine)
    let category: ExerciseCategory
}

extension AssistanceExercise {
    static let catalog: [AssistanceExercise] = [
        // LEGS (squat/deadlift leg drive)
        .init(id: "split_squat", name: "Heels-Elevated Split Squat",
              defaultWeight: 0, defaultReps: 12,
              allowWeightToggle: true, toggledWeight: 30,
              usesImpliedImplements: false, category: .legs),
        .init(id: "front_squat", name: "Front Squat",
              defaultWeight: 95, defaultReps: 8,
              allowWeightToggle: false, toggledWeight: 0,
              usesImpliedImplements: false, category: .legs),
        .init(id: "paused_squat", name: "Paused Squat (2s)",
              defaultWeight: 95, defaultReps: 5,
              allowWeightToggle: false, toggledWeight: 0,
              usesImpliedImplements: false, category: .legs),
        .init(id: "leg_press", name: "Leg Press",
              defaultWeight: 180, defaultReps: 12,
              allowWeightToggle: false, toggledWeight: 0,
              usesImpliedImplements: true, category: .legs),
        .init(id: "bulgarian", name: "Bulgarian Split Squat",
              defaultWeight: 0, defaultReps: 10,
              allowWeightToggle: true, toggledWeight: 30,
              usesImpliedImplements: false, category: .legs),
        .init(id: "lunges", name: "Walking Lunges",
              defaultWeight: 0, defaultReps: 12,
              allowWeightToggle: true, toggledWeight: 25,
              usesImpliedImplements: false, category: .legs),
        
        // PUSH (bench)
        .init(id: "triceps_ext", name: "Lying Triceps Extension (EZ)",
              defaultWeight: 25, defaultReps: 12,
              allowWeightToggle: false, toggledWeight: 0,
              usesImpliedImplements: true, category: .push),
        .init(id: "dips", name: "Dips",
              defaultWeight: 0, defaultReps: 10,
              allowWeightToggle: true, toggledWeight: 25,
              usesImpliedImplements: false, category: .push),
        .init(id: "close_grip", name: "Close-Grip Bench",
              defaultWeight: 95, defaultReps: 8,
              allowWeightToggle: false, toggledWeight: 0,
              usesImpliedImplements: false, category: .push),
        
        // PULL (row)
        .init(id: "spider_curls", name: "Spider Curls (DB)",
              defaultWeight: 30, defaultReps: 12,
              allowWeightToggle: false, toggledWeight: 0,
              usesImpliedImplements: false, category: .pull),
        .init(id: "hammer_curls", name: "Hammer Curls (DB)",
              defaultWeight: 30, defaultReps: 12,
              allowWeightToggle: false, toggledWeight: 0,
              usesImpliedImplements: false, category: .pull),
        .init(id: "face_pulls", name: "Face Pulls (Cable)",
              defaultWeight: 25, defaultReps: 15,
              allowWeightToggle: false, toggledWeight: 0,
              usesImpliedImplements: true, category: .pull),
        
        // CORE (deadlift/back)
        .init(id: "back_ext", name: "Back Extension",
              defaultWeight: 0, defaultReps: 12,
              allowWeightToggle: true, toggledWeight: 25,
              usesImpliedImplements: false, category: .core),
        .init(id: "hanging_leg", name: "Hanging Leg Raise",
              defaultWeight: 0, defaultReps: 10,
              allowWeightToggle: false, toggledWeight: 0,
              usesImpliedImplements: false, category: .core),
        .init(id: "ab_wheel", name: "Ab Wheel Rollout",
              defaultWeight: 0, defaultReps: 8,
              allowWeightToggle: false, toggledWeight: 0,
              usesImpliedImplements: false, category: .core),
        .init(id: "db_rdl", name: "RDL (DB)",
              defaultWeight: 30, defaultReps: 10,
              allowWeightToggle: false, toggledWeight: 0,
              usesImpliedImplements: false, category: .core),
        .init(id: "ssb_gm", name: "SSB Good Morning",
              defaultWeight: 95, defaultReps: 8,
              allowWeightToggle: false, toggledWeight: 0,
              usesImpliedImplements: false, category: .core),
    ]
    
    static func byID(_ id: String) -> AssistanceExercise? {
        catalog.first { $0.id == id }
    }
}
