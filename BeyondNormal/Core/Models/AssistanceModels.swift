import Foundation

enum ExerciseCategory: String, Codable, CaseIterable {
    case push, pull, legs, core
}

// Attribution for community/sharing
enum AssistanceSource: Codable, Equatable, Hashable {
    case builtIn
    case userCreated(author: String?)
    case imported(packId: String, author: String?)
}

// ⬇️ add near your other enums
enum EquipmentKind: String, Codable, CaseIterable {
    case bodyweight, dumbbells, barbell, machine, cable, other
}

struct AssistanceExercise: Identifiable, Codable, Hashable {
    // EXISTING FIELDS (unchanged)
    let id: String
    var name: String
    var defaultWeight: Double        // 0 = bodyweight
    var defaultReps: Int
    var allowWeightToggle: Bool      // e.g. dips, split squats with DBs
    var toggledWeight: Double        // default DB weight when toggled
    var usesImpliedImplements: Bool  // cosmetic label (EZ bar, machine)
    var category: ExerciseCategory

    // NEW FIELDS (future-proof for filtering & community)
    var areas: Set<FocusArea> = []           // e.g., [.deadlift, .squat]
    var tags: Set<AssistanceTag> = []        // e.g., [.hamstrings, .glutes]
    var source: AssistanceSource = .builtIn  // built-in unless user creates/imports
    var createdAt: Date = Date()
    var version: Int = 1
    
    // NEW
    var equipment: EquipmentKind = .bodyweight
    /// If equipment == .barbell and you want a non-45 bar, set this. Otherwise nil.
    var barWeightOverride: Double? = nil

    // ---- Initializers ----
    // 1) Back-compat init (existing)
    init(id: String,
         name: String,
         defaultWeight: Double,
         defaultReps: Int,
         allowWeightToggle: Bool,
         toggledWeight: Double,
         usesImpliedImplements: Bool,
         category: ExerciseCategory,
         equipment: EquipmentKind = .bodyweight,
         barWeightOverride: Double? = nil) {
        self.id = id
        self.name = name
        self.defaultWeight = defaultWeight
        self.defaultReps = defaultReps
        self.allowWeightToggle = allowWeightToggle
        self.toggledWeight = toggledWeight
        self.usesImpliedImplements = usesImpliedImplements
        self.category = category
        self.areas = []
        self.tags = []
        self.source = .builtIn
        self.createdAt = Date()
        self.version = 1
        self.equipment = equipment
        self.barWeightOverride = barWeightOverride
    }

    // 2) Creator-friendly init (existing)
    init(id: String,
         name: String,
         defaultWeight: Double,
         defaultReps: Int,
         allowWeightToggle: Bool,
         toggledWeight: Double,
         usesImpliedImplements: Bool,
         category: ExerciseCategory,
         areas: Set<FocusArea>,
         tags: Set<AssistanceTag>,
         authorDisplayName: String?,
         equipment: EquipmentKind = .bodyweight,
         barWeightOverride: Double? = nil) {
        self.id = id
        self.name = name
        self.defaultWeight = defaultWeight
        self.defaultReps = defaultReps
        self.allowWeightToggle = allowWeightToggle
        self.toggledWeight = toggledWeight
        self.usesImpliedImplements = usesImpliedImplements
        self.category = category
        self.areas = areas
        self.tags = tags
        self.source = .userCreated(author: authorDisplayName)
        self.createdAt = Date()
        self.version = 1
        self.equipment = equipment
        self.barWeightOverride = barWeightOverride
    }
    
    var isBarbell: Bool { equipment == .barbell }
    
    func effectiveBarWeight(defaultBar: Double = 45) -> Double {
        barWeightOverride ?? defaultBar
    }
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
              usesImpliedImplements: false, category: .core)
    ]

    static func byID(_ id: String) -> AssistanceExercise? {
        catalog.first { $0.id == id }
    }
}
