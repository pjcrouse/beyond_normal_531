import SwiftUI
import Foundation
import Combine
import UserNotifications

// MARK: - Main View

struct ContentView: View {
    // Training inputs
    @AppStorage("tm_squat")    private var tmSquat: Double = 315
    @AppStorage("tm_bench")    private var tmBench: Double = 225
    @AppStorage("tm_deadlift") private var tmDeadlift: Double = 405
    @AppStorage("tm_row")      private var tmRow: Double = 185
    @AppStorage("tm_press") private var tmPress: Double = 135

    @AppStorage("bar_weight")  private var barWeight: Double = 45
    @AppStorage("round_to")    private var roundTo: Double = 5
    @AppStorage("bbb_pct")     private var bbbPct: Double = 0.50

    // Assistance defaults (legacy)
    @AppStorage("assist_weight_squat")    private var assistWeightSquat: Double = 0
    @AppStorage("assist_weight_bench")    private var assistWeightBench: Double = 65
    @AppStorage("assist_weight_deadlift") private var assistWeightDeadlift: Double = 0
    @AppStorage("assist_weight_row")      private var assistWeightRow: Double = 0

    @AppStorage("timer_regular_sec") private var timerRegularSec: Int = 180
    @AppStorage("timer_bbb_sec")     private var timerBBBsec: Int = 120
    @AppStorage("current_week")      private var currentWeek: Int = 1

    @AppStorage("tm_progression_style") private var tmProgStyleRaw: String = "classic"
    @AppStorage("auto_advance_week")    private var autoAdvanceWeek: Bool = false

    // Selected assistance by main lift
    @AppStorage("assist_squat_id")    private var assistSquatID: String = "split_squat"
    @AppStorage("assist_bench_id")    private var assistBenchID: String = "triceps_ext"
    @AppStorage("assist_deadlift_id") private var assistDeadliftID: String = "back_ext"
    @AppStorage("assist_row_id")      private var assistRowID: String = "spider_curls"
    @AppStorage("assist_press_id") private var assistPressID: String = "triceps_ext" // safe default
    
    // 1 Rep Max Formula
    @AppStorage("one_rm_formula") private var oneRMFormulaRaw: String = "epley"
    
    // Configurable workouts per week support
    @AppStorage("workouts_per_week") private var workoutsPerWeek: Int = 4   // 3, 4, or 5
    @AppStorage("fourth_lift")       private var fourthLiftRaw: String = "row" // "row" | "press"
    
    // Fix for cycle/week
    @AppStorage("current_cycle") private var currentCycle: Int = 1

    @StateObject private var workoutState = WorkoutStateManager()
    @StateObject private var timer = TimerManager()
    @StateObject private var implements = ImplementWeights.shared

    @State private var workoutNotes: String = ""
    @State private var savedAlertText = ""
    @State private var showSettings = false
    @State private var showPRs = false
    @State private var selectedLift: Lift = .bench
    @State private var liveRepsText: String = ""
    @State private var showResetConfirm = false
    @State private var showSavedAlert = false
    @State private var showHistory = false
    @FocusState private var amrapFocused: Bool
    @FocusState private var notesFocused: Bool

    @State private var showGuide = false

    // Gate that views check before calling timer.start(...)
    @State private var allowTimerStarts = false
    
    @State private var showPRsSheet = false

    // Library for assistance lookup (still needed for selected exercise resolution)
    @EnvironmentObject private var assistanceLibrary: AssistanceLibrary

    private var isUpper: (Lift) -> Bool { { $0 == .bench || $0 == .press || $0 == .row } }
    private var isLower: (Lift) -> Bool { { $0 == .squat || $0 == .deadlift } }

    // Bump rules for Classic
    private func classicBumpAmount(for lift: Lift) -> Double {
        if isUpper(lift) { return 5 }   // +5 for upper
        if isLower(lift) { return 10 }  // +10 for lower
        return 0
    }

    // Cap rules for Auto (max per cycle change)
    private func autoMaxDelta(for lift: Lift) -> Double {
        if isUpper(lift) { return 10 }  // cap +10 upper
        if isLower(lift) { return 20 }  // cap +20 lower
        return 0
    }

    // Read/write TMs by lift
    private func getTM(_ lift: Lift) -> Double {
        switch lift {
        case .squat: return tmSquat
        case .bench: return tmBench
        case .deadlift: return tmDeadlift
        case .row: return tmRow
        case .press: return tmPress
        }
    }

    private func setTM(_ lift: Lift, _ value: Double) {
        let v = max(45, value.rounded())  // keep sane & whole lbs
        switch lift {
        case .squat: tmSquat = v
        case .bench: tmBench = v
        case .deadlift: tmDeadlift = v
        case .row: tmRow = v
        case .press: tmPress = v
        }
    }
    
    private func applyTMProgressionForNewCycle(from oldCycle: Int) {
        let liftsToProgress = activeLifts  // only what the program actually used

        if tmProgStyleRaw == "classic" {
            for lift in liftsToProgress {
                let bumped = getTM(lift) + classicBumpAmount(for: lift)
                setTM(lift, bumped)
            }
            return
        }

        // AUTO progression
        for lift in liftsToProgress {
            // Best est-1RM recorded THIS cycle for this lift
            let best = PRStore.shared.bestByCycle[PRKey(cycle: oldCycle, lift: lift.label)] ?? 0
            guard best > 0 else { continue } // nothing to update if no AMRAPs logged

            let targetTM = (Double(best) * 0.90).rounded() // 90% rule
            let currentTM = getTM(lift)

            // Cap the increase per cycle
            let maxUp = autoMaxDelta(for: lift)
            let delta = min(max(targetTM - currentTM, 0), maxUp)

            setTM(lift, currentTM + delta)
        }
    }
    
    private var oneRMFormula: OneRepMaxFormula {
        switch oneRMFormulaRaw.lowercased() {
        case "epley":    return .epley
        case "brzycki":  return .brzycki
        case "mayhew":   return .mayhew
        default:         return .epley   // safe default
        }
    }
    
    private var fourthLift: Lift {
        fourthLiftRaw.lowercased() == "press" ? .press : .row
    }

    private var activeLifts: [Lift] {
        switch workoutsPerWeek {
        case 3:  return [.squat, .bench, .deadlift]
        case 4:  return [.squat, .bench, .deadlift, fourthLift]
        default: return [.squat, .bench, .deadlift, .row, .press]  // 5+: both
        }
    }
    
    private let program = ProgramEngine()

    private var calculator: PlateCalculator {
        PlateCalculator(barWeight: barWeightForSelectedLift,
                        roundTo: roundTo,
                        inventory: [45, 35, 25, 10, 5, 2.5])
    }

    private var barWeightForSelectedLift: Double {
        implements.weight(for: selectedLift)
    }

    // MARK: - Small computed props

    private var currentScheme: WeekSchemeResult { program.weekScheme(for: currentWeek) }
    private var tmSelected: Double { tmFor(selectedLift) }
    private var topWeight: Double {
        let pct = currentScheme.main.last?.pct ?? 0.85
        return calculator.round(tmSelected * pct)
    }

    // Arm both the view-level and manager-level gates on first user action
    private func armTimers() {
        allowTimerStarts = true
        timer.allowStarts = true
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color(.systemBackground), Color(.secondarySystemBackground)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView { mainContent }
            }
            .navigationTitle("5/3/1 • Beyond Normal")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showHistory = true } label: {
                        Label("History", systemImage: "clock.arrow.circlepath")
                    }
                    .accessibilityLabel("History")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSettings = true } label: { Image(systemName: "gearshape") }
                        .accessibilityLabel("Settings")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showGuide = true } label: { Image(systemName: "questionmark.circle") }
                        .accessibilityLabel("User Guide")
                }
                // Keyboard toolbar - Done button
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        amrapFocused = false
                        notesFocused = false
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showPRsSheet = true } label: {
                        Image(systemName: "trophy.fill")
                    }
                    .accessibilityLabel("PRs")
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsSheet(
                tmSquat: $tmSquat,
                tmBench: $tmBench,
                tmDeadlift: $tmDeadlift,
                tmRow: $tmRow,
                tmPress: $tmPress,
                barWeight: $barWeight,
                roundTo: $roundTo,
                bbbPct: $bbbPct,
                timerRegularSec: $timerRegularSec,
                timerBBBsec: $timerBBBsec,
                tmProgStyleRaw: $tmProgStyleRaw,
                autoAdvanceWeek: $autoAdvanceWeek,
                oneRMFormulaRaw: $oneRMFormulaRaw,
                assistSquatID: $assistSquatID,
                assistBenchID: $assistBenchID,
                assistDeadliftID: $assistDeadliftID,
                assistRowID: $assistRowID,
                assistPressID: $assistPressID,
                workoutsPerWeek: $workoutsPerWeek,
                fourthLiftRaw: $fourthLiftRaw
            )
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showHistory) {
            HistorySheet(
                availableLifts: activeLifts,
                currentProgramWeek: currentWeek,
                currentCycle: currentCycle
            )
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showGuide) {
            NavigationStack { UserGuideView() }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .interactiveDismissDisabled(false)
        }
        .sheet(isPresented: $showPRsSheet) {
            PRsSheet(currentCycle: currentCycle, lifts: activeLifts)
                .presentationDetents([.medium, .large])
        }
        .alert("Reset current lift?", isPresented: $showResetConfirm) {
            Button("Reset", role: .destructive) { resetCurrentLift() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will clear all sets (main, BBB, assistance), AMRAP reps, and workout notes for \(selectedLift.label).")
        }
        .alert("Saved!", isPresented: $showSavedAlert, presenting: savedAlertText) { _ in
            Button("OK", role: .cancel) { }
        } message: { text in
            Text(text)
        }
        .onAppear {
            let center = UNUserNotificationCenter.current()
            center.delegate = LocalNotifDelegate.shared
            requestNotifsIfNeeded()

            // Ensure timer is fully idle at launch & blocked
            timer.reset()
            timer.allowStarts = false
            allowTimerStarts = false

            liveRepsText = repsText(for: selectedLift)

            // ✅ Ensure selectedLift is valid given the user's config
            if !activeLifts.contains(selectedLift) {
                selectedLift = activeLifts.first ?? .bench
            }
        }
        .onChange(of: workoutsPerWeek) { _, _ in
            if !activeLifts.contains(selectedLift) {
                selectedLift = activeLifts.first ?? .bench
            }
        }
        .onChange(of: fourthLiftRaw) { _, _ in
            if !activeLifts.contains(selectedLift) {
                selectedLift = activeLifts.first ?? .bench
            }
        }
        .onChange(of: selectedLift) { _, new in
            liveRepsText = repsText(for: new)
        }
        .onChange(of: liveRepsText) { _, _ in
            saveReps(liveRepsText, for: selectedLift)
        }
    }

    // MARK: - Main scroll content (split out)

    @ViewBuilder
    private var mainContent: some View {
        let m = currentWorkoutMetrics()
        let isWorkoutFinished = workoutState.isWorkoutFinished(lift: selectedLift.rawValue, week: currentWeek)

        VStack(spacing: 16) {
            headerView

            TrainingMaxesLine(
                tmSquat: tmSquat,
                tmBench: tmBench,
                tmDeadlift: tmDeadlift,
                tmRow: tmRow,
                tmPress: tmPress,
                activeLifts: activeLifts
            )

            QuickTargetHeader(
                week: currentWeek,
                liftLabel: selectedLift.label,
                topLine: currentScheme.topLine,
                topWeight: topWeight
            )

            PRDisclosureView(
                expanded: $showPRs,
                tm: tmSelected,
                rounder: { calculator.round($0) },
                label: selectedLift.label,
                currentCycle: currentCycle 
            )

            WorkoutBlock(
                selectedLift: $selectedLift,
                currentWeek: $currentWeek,
                workoutNotes: $workoutNotes,
                notesFocused: $notesFocused,
                amrapFocused: $amrapFocused,
                timer: timer,
                program: program,
                calculator: calculator,
                barWeightForSelectedLift: barWeightForSelectedLift,
                roundTo: roundTo,
                bbbPct: bbbPct,
                timerRegularSec: timerRegularSec,
                timerBBBsec: timerBBBsec,
                est1RM: { lift, w in
                    let reps = workoutState.getAMRAP(lift: lift.rawValue, week: currentWeek)
                    return estimate1RM(
                        weight: w,
                        reps: reps,
                        formula: oneRMFormula,
                        softWarnAt: 11,
                        hardCap: 15,
                        refuseAboveHardCap: true, // or false to cap instead of refuse
                        roundTo: roundTo
                    )
                },
                setBinding: setBinding,
                tmFor: { lift in tmFor(lift) },
                liveRepsText: $liveRepsText,
                workoutState: workoutState,
                allowTimerStarts: allowTimerStarts,
                armTimers: armTimers,
                isWorkoutFinished: isWorkoutFinished,
                currentFormula: oneRMFormula,
                availableLifts: activeLifts,
                currentCycle: currentCycle,
                startRest: { secs, fromUser in
                    startRest(secs, fromUser: fromUser)
                }
            )

            AssistanceBlock(
                selectedLift: $selectedLift,
                currentWeek: currentWeek,
                program: program,
                workoutState: workoutState,
                implements: implements,
                calculator: calculator,
                roundTo: roundTo,
                timer: timer,
                timerBBBsec: timerBBBsec,
                assistanceFor: assistanceExerciseFor(_:),
                assistSetBinding: assistSetBinding(_:),
                legacyAssistDefault: { lift in
                    switch lift {
                    case .squat:    return assistWeightSquat == 0 ? nil : assistWeightSquat
                    case .bench:    return assistWeightBench == 0 ? nil : assistWeightBench
                    case .deadlift: return assistWeightDeadlift == 0 ? nil : assistWeightDeadlift
                    case .row:      return assistWeightRow == 0 ? nil : assistWeightRow
                    case .press:    return assistWeightBench == 0 ? nil : assistWeightBench
                    }
                },
                allowTimerStarts: allowTimerStarts,
                armTimers: {
                    if !allowTimerStarts { allowTimerStarts = true }
                    if !timer.allowStarts { timer.allowStarts = true }
                },
                isWorkoutFinished: isWorkoutFinished,
                tmFor: { lift in tmFor(lift) },
                startRest: { secs, fromUser in
                    startRest(secs, fromUser: fromUser)
                }
            )

            SummaryCard(
                date: .now,
                est1RM: m.est,
                totals: (total: m.totalVol, main: m.mainVol, bbb: m.bbbVol, assist: m.assistVol)
            )
            .cardStyle()

            finishButton

            Divider().padding(.vertical, 6)

            resetButton

            Text("v0.1.0 • Implements Editor")
                .font(.footnote)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical)
    }

    // MARK: - Subviews

    private var headerView: some View {
        VStack(spacing: 6) {
            Group {
                if UIImage(named: "BeyondNormalLogo") != nil {
                    Image("BeyondNormalLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 220)
                        .accessibilityLabel("Beyond Normal")
                } else {
                    Text("Beyond Normal")
                        .font(.largeTitle.weight(.bold))
                }
            }

            // Cycle • Week chip (read-only; picker stays in WorkoutBlock)
            Text("Cycle \(currentCycle) • Week \(currentWeek)")
                .font(.caption)
                .monospacedDigit()
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule().fill(Color.secondary.opacity(0.15))
                )
                .accessibilityLabel("Cycle \(currentCycle), Week \(currentWeek)")
        }
        .padding(.horizontal)
    }

    private var finishButton: some View {
        Button {
            finishWorkout()
        } label: {
            Label("Finish Workout", systemImage: "checkmark.seal.fill")
                .font(.headline)
        }
        .buttonStyle(.borderedProminent)
        .accessibilityLabel("Finish workout")
    }

    private var resetButton: some View {
        Button(role: .destructive) {
            showResetConfirm = true
        } label: {
            Label("Reset Workout (Current Lift)", systemImage: "arrow.uturn.backward")
        }
        .accessibilityLabel("Reset current lift")
    }

    // MARK: - Helpers

    private func assistanceExerciseFor(_ lift: Lift) -> AssistanceExercise {
        let id: String
        switch lift {
        case .squat:    id = assistSquatID
        case .bench:    id = assistBenchID
        case .deadlift: id = assistDeadliftID
        case .row:      id = assistRowID
        case .press:    id = assistPressID
        }

        // 1) Try user-created first
        if let fromUser = assistanceLibrary.userCreated.first(where: { $0.id == id }) {
            return fromUser
        }
        // 2) Fall back to built-in catalog
        if let fromBuiltIn = AssistanceExercise.byID(id) {
            return fromBuiltIn
        }
        // 3) Absolute fallback: the first catalog item (should never happen in practice)
        return AssistanceExercise.catalog.first!
    }

    private func tmFor(_ lift: Lift) -> Double {
        switch lift {
        case .squat: return tmSquat
        case .bench: return tmBench
        case .deadlift: return tmDeadlift
        case .row: return tmRow
        case .press:    return tmPress
        }
    }

    private func setBinding(_ num: Int) -> Binding<Bool> {
        Binding(
            get: { self.workoutState.getSetComplete(lift: self.selectedLift.rawValue, week: self.currentWeek, set: num) },
            set: { newValue in
                self.workoutState.setSetComplete(lift: self.selectedLift.rawValue, week: self.currentWeek, set: num, value: newValue)
            }
        )
    }

    private func assistSetBinding(_ n: Int) -> Binding<Bool> {
        Binding(
            get: { self.workoutState.getAssistComplete(lift: self.selectedLift.rawValue, week: self.currentWeek, set: n) },
            set: { newValue in
                self.workoutState.setAssistComplete(lift: self.selectedLift.rawValue, week: self.currentWeek, set: n, value: newValue)
            }
        )
    }

    private func resetCurrentLift() {
        workoutState.resetLift(lift: selectedLift.rawValue, week: currentWeek)
        workoutNotes = ""
        liveRepsText = ""

        switch selectedLift {
        case .squat:    assistWeightSquat = 0
        case .bench:    assistWeightBench = 65
        case .deadlift: assistWeightDeadlift = 0
        case .row:      assistWeightRow = 0
        case .press:    assistWeightBench = 65 
        }
    }

    private func repsText(for lift: Lift) -> String {
        let r = workoutState.getAMRAP(lift: lift.rawValue, week: currentWeek)
        return r == 0 ? "" : String(r)
    }

    private func saveReps(_ text: String, for lift: Lift) {
        let r = Int(text) ?? 0
        workoutState.setAMRAP(lift: lift.rawValue, week: currentWeek, reps: r)
    }

    private func currentWorkoutMetrics() -> (est: Double, totalVol: Int, mainVol: Int, bbbVol: Int, assistVol: Int) {
        let scheme = program.weekScheme(for: currentWeek)
        let tmSel = tmFor(selectedLift)

        func mainSetVol(_ idx: Int) -> Double {
            let s = scheme.main[idx]
            let w = calculator.round(tmSel * s.pct)
            let reps = s.amrap ? Double(max(workoutState.getAMRAP(lift: selectedLift.rawValue, week: currentWeek), 0)) : Double(s.reps)
            return w * reps
        }
        let mainVol = Int(mainSetVol(0) + mainSetVol(1) + mainSetVol(2))

        let defaultBBBW = calculator.round(tmSel * bbbPct)
        var bbbVol = 0.0
        for setNum in 1...5 {
            let mainSetNum = setNum + 3 // sets 4–8
            if workoutState.getSetComplete(lift: selectedLift.rawValue, week: currentWeek, set: mainSetNum) {
                let weight = workoutState.getBBBWeight(lift: selectedLift.rawValue, week: currentWeek, set: setNum) ?? defaultBBBW
                let reps = workoutState.getBBBReps(lift: selectedLift.rawValue, week: currentWeek, set: setNum) ?? 10
                bbbVol += weight * Double(reps)
            }
        }

        let ex = assistanceExerciseFor(selectedLift)
        let defaultAssistW = ex.defaultWeight > 0 ? ex.defaultWeight :
            (ex.allowWeightToggle && workoutState.getAssistUseWeight(lift: selectedLift.rawValue, week: currentWeek) ? ex.toggledWeight : 0)

        var assistVol = 0.0
        for setNum in 1...3 {
            if currentScheme.showBBB && workoutState.getAssistComplete(lift: selectedLift.rawValue, week: currentWeek, set: setNum) {
                let weight = workoutState.getAssistWeight(lift: selectedLift.rawValue, week: currentWeek, set: setNum) ?? defaultAssistW
                let reps = workoutState.getAssistReps(lift: selectedLift.rawValue, week: currentWeek, set: setNum) ?? ex.defaultReps
                assistVol += weight * Double(reps)
            }
        }

        let totalVol = Int(mainVol) + Int(bbbVol) + Int(assistVol)

        let top = currentScheme.main[2]
        let est: Double = {
            guard top.amrap else { return 0 }
            let amrapReps = workoutState.getAMRAP(lift: selectedLift.rawValue, week: currentWeek)
            let w = calculator.round(tmSel * top.pct)

            let r = estimate1RM(
                weight: w,
                reps: amrapReps,
                formula: oneRMFormula,
                softWarnAt: 11,
                hardCap: 15,
                refuseAboveHardCap: true,
                roundTo: roundTo
            )
            return r.e1RM
        }()

        return (est, totalVol, Int(mainVol), Int(bbbVol), Int(assistVol))
    }

    private func finishWorkout() {
        let metrics = currentWorkoutMetrics()
        let liftLabel = selectedLift.label

        savedAlertText = String(
            format: "Logged %@ • Est 1RM %@ • Volume %@ lb",
            liftLabel,
            Int(metrics.est).formatted(.number),
            metrics.totalVol.formatted(.number)
        )

        // Save entry (now including week/cycle)
        let entry = WorkoutEntry(
            date: .now,
            lift: selectedLift.label,
            est1RM: metrics.est,
            totalVolume: metrics.totalVol,
            bbbPct: bbbPct,
            amrapReps: workoutState.getAMRAP(lift: selectedLift.rawValue, week: currentWeek),
            notes: workoutNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : workoutNotes,
            programWeek: currentWeek,
            cycle: currentCycle
        )
        WorkoutStore.shared.append(entry)

        // Consider PR from AMRAP estimate
        if metrics.est > 0 {
            PRStore.shared.considerPR(
                cycle: currentCycle,
                lift: selectedLift.label,
                est1RM: Int(metrics.est.rounded())
            )
        }

        // Mark finished in state
        workoutState.markWorkoutFinished(lift: selectedLift.rawValue, week: currentWeek)
        workoutState.markLiftComplete(selectedLift.rawValue, week: currentWeek)

        // Reset timers and clear notes field
        timer.reset()
        workoutNotes = ""

        // Auto advance logic
        if autoAdvanceWeek {
            // (already marked this lift complete above)
            if workoutState.allLiftsComplete(for: currentWeek, totalLifts: activeLifts.count) {
                if currentWeek == 4 {
                    // ---- End of cycle: roll to Week 1 of next cycle + apply TM progression ----
                    let oldCycle = currentCycle
                    currentCycle += 1
                    currentWeek = 1
                    workoutState.resetCompletedLifts(for: currentWeek)

                    // Capture old TMs for summary
                    let oldSQ = tmSquat
                    let oldBP = tmBench
                    let oldDL = tmDeadlift
                    let oldRW = tmRow
                    let oldPR = tmPress

                    // Apply TM progression at cycle rollover
                    var tms = TMSet(squat: tmSquat, bench: tmBench, deadlift: tmDeadlift, row: tmRow, press: tmPress)
                    let style = TMProgressionStyle(rawValue: tmProgStyleRaw.lowercased()) ?? .classic
                    switch style {
                    case .classic:
                        applyClassic(&tms, active: activeLifts)
                    case .auto:
                        // You can restrict to “last cycle” entries if you want, but whole history works too.
                        let recent = WorkoutStore.shared.load()
                        applyAuto(&tms, active: activeLifts, entries: recent)  // uses your caps/floors
                    }

                    // Persist progressed TMs (rounded to your increment)
                    tmSquat    = LoadRounder.round(tms.squat,    to: roundTo)
                    tmBench    = LoadRounder.round(tms.bench,    to: roundTo)
                    tmDeadlift = LoadRounder.round(tms.deadlift, to: roundTo)
                    tmRow      = LoadRounder.round(tms.row,      to: roundTo)
                    tmPress    = LoadRounder.round(tms.press,    to: roundTo)

                    // Append a concise delta summary (only for lifts in use this cycle)
                    var lines: [String] = []
                    if activeLifts.contains(.squat) {
                        let d = Int(tmSquat.rounded()) - Int(oldSQ.rounded())
                        lines.append("Squat: \(Int(oldSQ.rounded())) → \(Int(tmSquat.rounded())) \(d >= 0 ? "↑" : "↓")\(abs(d))")
                    }
                    if activeLifts.contains(.bench) {
                        let d = Int(tmBench.rounded()) - Int(oldBP.rounded())
                        lines.append("Bench: \(Int(oldBP.rounded())) → \(Int(tmBench.rounded())) \(d >= 0 ? "↑" : "↓")\(abs(d))")
                    }
                    if activeLifts.contains(.deadlift) {
                        let d = Int(tmDeadlift.rounded()) - Int(oldDL.rounded())
                        lines.append("Deadlift: \(Int(oldDL.rounded())) → \(Int(tmDeadlift.rounded())) \(d >= 0 ? "↑" : "↓")\(abs(d))")
                    }
                    if activeLifts.contains(.row) {
                        let d = Int(tmRow.rounded()) - Int(oldRW.rounded())
                        lines.append("Row: \(Int(oldRW.rounded())) → \(Int(tmRow.rounded())) \(d >= 0 ? "↑" : "↓")\(abs(d))")
                    }
                    if activeLifts.contains(.press) {
                        let d = Int(tmPress.rounded()) - Int(oldPR.rounded())
                        lines.append("Press: \(Int(oldPR.rounded())) → \(Int(tmPress.rounded())) \(d >= 0 ? "↑" : "↓")\(abs(d))")
                    }

                    savedAlertText += "\nCycle \(oldCycle) complete — advancing to Cycle \(currentCycle), Week 1!"
                    if !lines.isEmpty {
                        savedAlertText += "\n\nNext-cycle TMs:\n" + lines.joined(separator: "\n")
                    }
                } else {
                    // ---- Mid-cycle: just advance the week ----
                    currentWeek += 1
                    workoutState.resetCompletedLifts(for: currentWeek)
                    savedAlertText += "\nAll lifts complete — advancing to Week \(currentWeek)!"
                }
            }
        }

        showSavedAlert = true
    }

    private func requestNotifsIfNeeded() {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { s in
            if s.authorizationStatus == .notDetermined {
                center.requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
            }
        }
    }
    
    private func tmChangeLine(_ name: String, _ old: Double, _ new: Double) -> String {
        let d = Int(new.rounded()) - Int(old.rounded())
        let arrow = d >= 0 ? "↑" : "↓"
        return "\(name): \(Int(old.rounded())) → \(Int(new.rounded())) \(arrow)\(abs(d))"
    }

    private func startRest(_ seconds: Int, fromUser: Bool) {
        // Only arm on user action
        if fromUser {
            armTimers() // sets allowTimerStarts = true and timer.allowStarts = true
        }
        // Never start unless both gates are open
        guard allowTimerStarts, timer.allowStarts else { return }
        timer.start(seconds: seconds)
    }
}
