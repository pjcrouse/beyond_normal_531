import Foundation

struct WorkoutEntry: Identifiable, Codable {
    let id: UUID
    let date: Date
    let lift: String
    let est1RM: Double
    let totalVolume: Int
    let bbbPct: Double
    let amrapReps: Int
    let notes: String?
    let configKey: String

    // NEW: program tracking
    let programWeek: Int
    let cycle: Int

    init(
        id: UUID = UUID(),
        date: Date,
        lift: String,
        est1RM: Double,
        totalVolume: Int,
        bbbPct: Double,
        amrapReps: Int,
        notes: String?,
        programWeek: Int,
        cycle: Int,
        configKey: String
    ) {
        self.id = id
        self.date = date
        self.lift = lift
        self.est1RM = est1RM
        self.totalVolume = totalVolume
        self.bbbPct = bbbPct
        self.amrapReps = amrapReps
        self.notes = notes
        self.programWeek = programWeek
        self.cycle = cycle
        self.configKey = configKey 
    }
}
