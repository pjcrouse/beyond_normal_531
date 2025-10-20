import SwiftUI

@MainActor
final class ProgramSettings: ObservableObject {

    // Namespaced keys (stable, human-readable)
    private struct Key {
        static let userDisplayName   = "bn.user_display_name"

        static let tmSquat           = "bn.tm.squat"
        static let tmBench           = "bn.tm.bench"
        static let tmDeadlift        = "bn.tm.deadlift"
        static let tmRow             = "bn.tm.row"
        static let tmPress           = "bn.tm.press"

        static let barWeight         = "bn.bar_weight"
        static let roundTo           = "bn.round_to"

        static let bbbPercent        = "bn.bbb_percent"       // store as Double 0.40...0.70

        static let timerRegularSec   = "bn.timer.regular"
        static let timerBBBSec       = "bn.timer.bbb"

        static let oneRMFormula      = "one_rm_formula"       // existing app key
        static let progressionStyle  = "tm_progression_style" // existing app key
        static let autoTMPercent     = "bn.auto_tm_percent"   // 80...95

        static let workoutsPerWeek   = "bn.workouts_per_week" // 3/4/5
        static let fourthLiftRaw     = "bn.fourth_lift"       // "row" | "press"

        static let assistSquatID     = "bn.assist.squat"
        static let assistBenchID     = "bn.assist.bench"
        static let assistDeadliftID  = "bn.assist.deadlift"
        static let assistRowID       = "bn.assist.row"
        static let assistPressID     = "bn.assist.press"

        static let autoAdvanceWeek   = "bn.auto_advance_week"
        static let currentCycle      = "current_cycle"        // you were already using this
    }

    // Raw persisted storage
    @AppStorage(Key.userDisplayName)   private var userDisplayNameRaw: String = ""

    @AppStorage(Key.tmSquat)           private var tmSquatRaw: Double = 315
    @AppStorage(Key.tmBench)           private var tmBenchRaw: Double = 225
    @AppStorage(Key.tmDeadlift)        private var tmDeadliftRaw: Double = 405
    @AppStorage(Key.tmRow)             private var tmRowRaw: Double = 185
    @AppStorage(Key.tmPress)           private var tmPressRaw: Double = 135

    @AppStorage(Key.barWeight)         private var barWeightRaw: Double = 45
    @AppStorage(Key.roundTo)           private var roundToRaw: Double = 5

    @AppStorage(Key.bbbPercent)        private var bbbPercentRaw: Double = 0.50

    @AppStorage(Key.timerRegularSec)   private var timerRegularSecRaw: Int = 180
    @AppStorage(Key.timerBBBSec)       private var timerBBBSecRaw: Int = 120

    @AppStorage(Key.oneRMFormula)      private var oneRMFormulaRaw: String = OneRepMaxFormula.epley.rawValue
    @AppStorage(Key.progressionStyle)  private var progressionStyleRaw: String = ProgressionStyle.classic.rawValue
    @AppStorage(Key.autoTMPercent)     private var autoTMPercentRaw: Int = 90

    @AppStorage(Key.workoutsPerWeek)   private var workoutsPerWeekRaw: Int = 4
    @AppStorage(Key.fourthLiftRaw)     private var fourthLiftRawRaw: String = "row"

    @AppStorage(Key.assistSquatID)     private var assistSquatIDRaw: String = "split_squat"
    @AppStorage(Key.assistBenchID)     private var assistBenchIDRaw: String = "triceps_ext"
    @AppStorage(Key.assistDeadliftID)  private var assistDeadliftIDRaw: String = "back_ext"
    @AppStorage(Key.assistRowID)       private var assistRowIDRaw: String = "spider_curls"
    @AppStorage(Key.assistPressID)     private var assistPressIDRaw: String = "triceps_ext"

    @AppStorage(Key.autoAdvanceWeek)   private var autoAdvanceWeekRaw: Bool = true
    @AppStorage(Key.currentCycle)      private var currentCycleRaw: Int = 1

    // App-facing state (Published so views can bind; give defaults here)
    @Published var userDisplayName: String = ""

    @Published var tmSquat: Double = 315
    @Published var tmBench: Double = 225
    @Published var tmDeadlift: Double = 405
    @Published var tmRow: Double = 185
    @Published var tmPress: Double = 135

    @Published var barWeight: Double = 45
    @Published var roundTo: Double = 5

    @Published var bbbPercent: Double = 0.50

    @Published var timerRegularSec: Int = 180
    @Published var timerBBBSec: Int = 120

    @Published var oneRMFormula: OneRepMaxFormula = .epley
    @Published var progressionStyle: ProgressionStyle = .classic
    @Published var autoTMPercent: Int = 90

    @Published var workoutsPerWeek: Int = 4
    @Published var fourthLiftRaw: String = "row"

    @Published var assistSquatID: String = "split_squat"
    @Published var assistBenchID: String = "triceps_ext"
    @Published var assistDeadliftID: String = "back_ext"
    @Published var assistRowID: String = "spider_curls"
    @Published var assistPressID: String = "triceps_ext"

    @Published var autoAdvanceWeek: Bool = true
    @Published var currentCycle: Int = 1

    init() {
        // Seed Published from UserDefaults without touching the @AppStorage wrappers
        let d = UserDefaults.standard

        userDisplayName   = d.string(forKey: Key.userDisplayName) ?? ""

        tmSquat           = d.object(forKey: Key.tmSquat)       as? Double ?? 315
        tmBench           = d.object(forKey: Key.tmBench)       as? Double ?? 225
        tmDeadlift        = d.object(forKey: Key.tmDeadlift)    as? Double ?? 405
        tmRow             = d.object(forKey: Key.tmRow)         as? Double ?? 185
        tmPress           = d.object(forKey: Key.tmPress)       as? Double ?? 135

        barWeight         = d.object(forKey: Key.barWeight)     as? Double ?? 45
        roundTo           = d.object(forKey: Key.roundTo)       as? Double ?? 5

        bbbPercent        = d.object(forKey: Key.bbbPercent)    as? Double ?? 0.50

        timerRegularSec   = d.object(forKey: Key.timerRegularSec) as? Int ?? 180
        timerBBBSec       = d.object(forKey: Key.timerBBBSec)     as? Int ?? 120

        let rawFormula    = (d.string(forKey: Key.oneRMFormula) ?? OneRepMaxFormula.epley.rawValue).lowercased()
        oneRMFormula      = OneRepMaxFormula(rawValue: rawFormula) ?? .epley

        let rawStyle      = d.string(forKey: Key.progressionStyle) ?? ProgressionStyle.classic.rawValue
        progressionStyle  = ProgressionStyle(rawValue: rawStyle) ?? .classic

        autoTMPercent     = d.object(forKey: Key.autoTMPercent) as? Int ?? 90

        workoutsPerWeek   = d.object(forKey: Key.workoutsPerWeek) as? Int ?? 4
        fourthLiftRaw     = d.string(forKey: Key.fourthLiftRaw) ?? "row"

        assistSquatID     = d.string(forKey: Key.assistSquatID) ?? "split_squat"
        assistBenchID     = d.string(forKey: Key.assistBenchID) ?? "triceps_ext"
        assistDeadliftID  = d.string(forKey: Key.assistDeadliftID) ?? "back_ext"
        assistRowID       = d.string(forKey: Key.assistRowID) ?? "spider_curls"
        assistPressID     = d.string(forKey: Key.assistPressID) ?? "triceps_ext"

        autoAdvanceWeek   = d.object(forKey: Key.autoAdvanceWeek) as? Bool ?? true
        currentCycle      = d.object(forKey: Key.currentCycle)    as? Int ?? 1
    }

    // Keep raw storage in sync whenever Published changes.
    // (didSet on each property is simplest/robust; place right after each Published var if you prefer.)
    // To keep this file readable, do it here explicitly:

    // Sync helpers
    private func sync() {
        userDisplayNameRaw   = userDisplayName

        tmSquatRaw           = tmSquat
        tmBenchRaw           = tmBench
        tmDeadliftRaw        = tmDeadlift
        tmRowRaw             = tmRow
        tmPressRaw           = tmPress

        barWeightRaw         = barWeight
        roundToRaw           = roundTo

        bbbPercentRaw        = bbbPercent

        timerRegularSecRaw   = timerRegularSec
        timerBBBSecRaw       = timerBBBSec

        oneRMFormulaRaw      = oneRMFormula.rawValue
        progressionStyleRaw  = progressionStyle.rawValue
        autoTMPercentRaw     = autoTMPercent

        workoutsPerWeekRaw   = workoutsPerWeek
        fourthLiftRawRaw     = fourthLiftRaw

        assistSquatIDRaw     = assistSquatID
        assistBenchIDRaw     = assistBenchID
        assistDeadliftIDRaw  = assistDeadliftID
        assistRowIDRaw       = assistRowID
        assistPressIDRaw     = assistPressID

        autoAdvanceWeekRaw   = autoAdvanceWeek
        currentCycleRaw      = currentCycle
    }

    // Observe changes and sync (SwiftUI will call objectWillChange; we just mirror to UserDefaults)
    // You can prefer didSet on each Published property; or keep one onChange in the main settings view.
    // Minimal: expose a method for SettingsSheet to call after edits:
    func save() { sync() }
}
