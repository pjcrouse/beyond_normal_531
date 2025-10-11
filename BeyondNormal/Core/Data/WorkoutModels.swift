import Foundation

struct WorkoutEntry: Codable, Identifiable {
    let id: UUID
    let date: Date
    let lift: String
    let est1RM: Double
    let totalVolume: Int
    let bbbPct: Double
    let amrapReps: Int
    let notes: String?

    init(date: Date, lift: String, est1RM: Double, totalVolume: Int,
         bbbPct: Double, amrapReps: Int, notes: String? = nil) {
        self.id = UUID()
        self.date = date
        self.lift = lift
        self.est1RM = est1RM
        self.totalVolume = totalVolume
        self.bbbPct = bbbPct
        self.amrapReps = amrapReps
        self.notes = notes
    }
}
