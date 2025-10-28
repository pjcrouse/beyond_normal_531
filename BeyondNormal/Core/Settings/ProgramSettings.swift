import Foundation
import SwiftUI

@MainActor
final class ProgramSettings: ObservableObject {

    // MARK: - Keys (namespaced + stable)
    private struct Key {
        static let userDisplayName   = "bn.user_display_name"
        static let authorID          = "bn.author_id"          // ← add a namespaced key

        static let tmSquat           = "bn.tm.squat"
        static let tmBench           = "bn.tm.bench"
        static let tmDeadlift        = "bn.tm.deadlift"
        static let tmRow             = "bn.tm.row"
        static let tmPress           = "bn.tm.press"

        static let barWeight         = "bn.bar_weight"
        static let roundTo           = "bn.round_to"

        static let bbbPercent        = "bn.bbb_percent"

        static let timerRegularSec   = "bn.timer.regular"
        static let timerBBBSec       = "bn.timer.bbb"

        static let oneRMFormula      = "one_rm_formula"
        static let progressionStyle  = "tm_progression_style"
        static let autoTMPercent     = "bn.auto_tm_percent"

        static let workoutsPerWeek   = "bn.workouts_per_week"
        static let fourthLiftRaw     = "bn.fourth_lift"

        static let assistSquatID     = "bn.assist.squat"
        static let assistBenchID     = "bn.assist.bench"
        static let assistDeadliftID  = "bn.assist.deadlift"
        static let assistRowID       = "bn.assist.row"
        static let assistPressID     = "bn.assist.press"

        static let autoAdvanceWeek   = "bn.auto_advance_week"
        static let currentCycle      = "current_cycle"
    }

    // MARK: - Raw persisted storage (@AppStorage mirrors)
    @AppStorage(Key.userDisplayName)   private var userDisplayNameRaw: String = ""
    @AppStorage(Key.authorID)          private var authorIDRaw: String = ""   // ← use namespaced key

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

    @AppStorage(Key.workoutsPerWeek)   private var workoutsPerWeekRaw: Int = 3
    @AppStorage(Key.fourthLiftRaw)     private var fourthLiftRawRaw: String = "row"

    @AppStorage(Key.assistSquatID)     private var assistSquatIDRaw: String = "split_squat"
    @AppStorage(Key.assistBenchID)     private var assistBenchIDRaw: String = "triceps_ext"
    @AppStorage(Key.assistDeadliftID)  private var assistDeadliftIDRaw: String = "back_ext"
    @AppStorage(Key.assistRowID)       private var assistRowIDRaw: String = "spider_curls"
    @AppStorage(Key.assistPressID)     private var assistPressIDRaw: String = "triceps_ext"

    @AppStorage(Key.autoAdvanceWeek)   private var autoAdvanceWeekRaw: Bool = true
    @AppStorage(Key.currentCycle)      private var currentCycleRaw: Int = 1
    
    // 🔧 Joker configuration (global)
    @AppStorage("jokerSetsEnabled") var jokerSetsEnabled: Bool = true
    @AppStorage("jokerAmrapRepCap") var jokerAmrapRepCap: Int = 12
    @AppStorage("jokerTripleStepPct") var jokerTripleStepPct: Double = 0.05  // 5% jumps for 3s
    @AppStorage("jokerSingleStepPct") var jokerSingleStepPct: Double = 0.10  // 10% jumps for 1s
    @AppStorage("jokerMaxOverTMPct")  var jokerMaxOverTMPct: Double  = 0.10  // cap at +10% over TM
    @AppStorage("jokerTrigger3s") var jokerTrigger3s: Int = 6  // Week 2 (3s): prompt at ≥6
    @AppStorage("jokerTrigger1s") var jokerTrigger1s: Int = 2  // Week 3 (1s): prompt at ≥2

    // MARK: - App-facing (Published)
    @Published var userDisplayName: String = "" {
        didSet {
            // hard cap: 24 graphemes
            let clean = sanitizedDisplayName(userDisplayName)
            let capped = limitedGraphemes(clean, max: 24)
            if capped != userDisplayName { userDisplayName = capped }
        }
    }

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

    @Published var workoutsPerWeek: Int = 3
    @Published var fourthLiftRaw: String = "row"

    @Published var assistSquatID: String = "split_squat"
    @Published var assistBenchID: String = "triceps_ext"
    @Published var assistDeadliftID: String = "back_ext"
    @Published var assistRowID: String = "spider_curls"
    @Published var assistPressID: String = "triceps_ext"

    @Published var autoAdvanceWeek: Bool = true
    @Published var currentCycle: Int = 1

    // MARK: - Init (seed Published from UserDefaults)
    init() {
        let d = UserDefaults.standard

        let raw = d.string(forKey: Key.userDisplayName) ?? ""
        userDisplayName = limitedGraphemes(sanitizedDisplayName(raw), max: 24)

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

        workoutsPerWeek   = d.object(forKey: Key.workoutsPerWeek) as? Int ?? 3
        fourthLiftRaw     = d.string(forKey: Key.fourthLiftRaw) ?? "row"

        assistSquatID     = d.string(forKey: Key.assistSquatID) ?? "split_squat"
        assistBenchID     = d.string(forKey: Key.assistBenchID) ?? "close_grip"
        assistDeadliftID  = d.string(forKey: Key.assistDeadliftID) ?? "barbell_rdl"
        assistRowID       = d.string(forKey: Key.assistRowID) ?? "spider_curls"
        assistPressID     = d.string(forKey: Key.assistPressID) ?? "seated_db_press"

        autoAdvanceWeek   = d.object(forKey: Key.autoAdvanceWeek) as? Bool ?? true
        currentCycle      = d.object(forKey: Key.currentCycle)    as? Int ?? 1

        // Ensure a stable author UUID exists from first launch.
        if authorIDRaw.isEmpty {
            authorIDRaw = UUID().uuidString
        }
    }

    // MARK: - Persist back to @AppStorage
    private func sync() {
        userDisplayNameRaw   = limitedGraphemes(sanitizedDisplayName(userDisplayName), max: 24)

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
        // authorIDRaw is managed once in init; no need to update unless you add UI to rotate it.
    }

    /// Call this from SettingsSheet "Save" (you already do)
    func save() { sync() }

    // MARK: - Export helpers for attribution
    var authorID: UUID {
        if let u = UUID(uuidString: authorIDRaw) { return u }
        let fresh = UUID()
        authorIDRaw = fresh.uuidString
        return fresh
    }

    var displayAuthorName: String {
        let n = userDisplayName.trimmingCharacters(in: .whitespacesAndNewlines)
        return n.isEmpty ? "Anonymous" : n
    }
}
