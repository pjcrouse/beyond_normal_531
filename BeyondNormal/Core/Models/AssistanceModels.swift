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
    var authorDisplayName: String? = nil
    
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
        self.authorDisplayName = authorDisplayName 
    }
    
    var isBarbell: Bool { equipment == .barbell }
    
    func effectiveBarWeight(defaultBar: Double = 45) -> Double {
        barWeightOverride ?? defaultBar
    }
}

extension AssistanceExercise {
    static let catalog: [AssistanceExercise] = [
        // -------------------------
        // SQUAT (2–3)
        // -------------------------
        .init(id: "split_squat", name: "Heels-Elevated Split Squat",
              defaultWeight: 0, defaultReps: 12,
              allowWeightToggle: true, toggledWeight: 30,
              usesImpliedImplements: false, category: .legs,
              equipment: .dumbbells),
        .init(id: "front_squat", name: "Front Squat",
              defaultWeight: 95, defaultReps: 8,
              allowWeightToggle: false, toggledWeight: 0,
              usesImpliedImplements: false, category: .legs,
              equipment: .barbell),
        .init(id: "paused_squat", name: "Paused Squat (2s)",
              defaultWeight: 95, defaultReps: 5,
              allowWeightToggle: false, toggledWeight: 0,
              usesImpliedImplements: false, category: .legs,
              equipment: .barbell),

        // -------------------------
        // BENCH (2–3)
        // -------------------------
        .init(id: "close_grip", name: "Close-Grip Bench",
              defaultWeight: 95, defaultReps: 8,
              allowWeightToggle: false, toggledWeight: 0,
              usesImpliedImplements: false, category: .push,
              equipment: .barbell),
        .init(id: "db_bench", name: "Dumbbell Bench Press",
              defaultWeight: 40, defaultReps: 10,
              allowWeightToggle: false, toggledWeight: 0,
              usesImpliedImplements: false, category: .push,
              equipment: .dumbbells),
        .init(id: "dips", name: "Dips",
              defaultWeight: 0, defaultReps: 10,
              allowWeightToggle: true, toggledWeight: 25,
              usesImpliedImplements: false, category: .push,
              equipment: .bodyweight),

        // -------------------------
        // ROW (2–3)
        // -------------------------
        .init(id: "lat_pulldown", name: "Lat Pulldown",
              defaultWeight: 70, defaultReps: 10,
              allowWeightToggle: false, toggledWeight: 0,
              usesImpliedImplements: false, category: .pull,
              equipment: .cable),
        .init(id: "spider_curls", name: "Spider Curls (DB)",
              defaultWeight: 30, defaultReps: 12,
              allowWeightToggle: false, toggledWeight: 0,
              usesImpliedImplements: false, category: .pull),
        .init(id: "pullups", name: "Pull-Ups / Chin-Ups",
              defaultWeight: 0, defaultReps: 6,
              allowWeightToggle: true, toggledWeight: 25,
              usesImpliedImplements: false, category: .pull,
              equipment: .bodyweight),
        
        
        // -------------------------
        // OVERHEAD PRESS (2–3)
        // -------------------------
        .init(id: "seated_db_press", name: "Seated Dumbbell Press",
              defaultWeight: 35, defaultReps: 10,
              allowWeightToggle: false, toggledWeight: 0,
              usesImpliedImplements: false, category: .push,
              equipment: .dumbbells),
        .init(id: "push_press", name: "Push Press",
              defaultWeight: 95, defaultReps: 5,
              allowWeightToggle: false, toggledWeight: 0,
              usesImpliedImplements: false, category: .push,
              equipment: .barbell),
        .init(id: "lateral_raise", name: "Lateral Raise",
              defaultWeight: 15, defaultReps: 12,
              allowWeightToggle: false, toggledWeight: 0,
              usesImpliedImplements: false, category: .push,
              equipment: .dumbbells),

        // -------------------------
        // DEADLIFT (2–3)
        // -------------------------
        .init(id: "barbell_rdl", name: "Romanian Deadlift (Barbell)",
              defaultWeight: 95, defaultReps: 8,
              allowWeightToggle: false, toggledWeight: 0,
              usesImpliedImplements: false, category: .pull,
              equipment: .barbell),
        .init(id: "deficit_dl", name: "Deficit Deadlift",
              defaultWeight: 95, defaultReps: 5,
              allowWeightToggle: false, toggledWeight: 0,
              usesImpliedImplements: false, category: .pull,
              equipment: .barbell),
        .init(id: "barbell_row", name: "Barbell Row",
              defaultWeight: 95, defaultReps: 8,
              allowWeightToggle: false, toggledWeight: 0,
              usesImpliedImplements: false, category: .pull,
              equipment: .barbell),
    ]

    static func byID(_ id: String) -> AssistanceExercise? {
        catalog.first { $0.id == id }
    }
}
