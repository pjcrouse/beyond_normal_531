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

    @AppStorage("bar_weight")  private var barWeight: Double = 45   // global fallback (not used for plate math when per-exercise is present)
    @AppStorage("round_to")    private var roundTo: Double = 5
    @AppStorage("bbb_pct")     private var bbbPct: Double = 0.50

    // Assistance defaults (legacy)
    @AppStorage("assist_weight_squat")    private var assistWeightSquat: Double = 0
    @AppStorage("assist_weight_bench")    private var assistWeightBench: Double = 65
    @AppStorage("assist_weight_deadlift") private var assistWeightDeadlift: Double = 0
    @AppStorage("assist_weight_row")      private var assistWeightRow: Double = 0

    @AppStorage("timer_regular_sec") private var timerRegularSec: Int = 240
    @AppStorage("timer_bbb_sec")     private var timerBBBsec: Int = 180
    @AppStorage("current_week")      private var currentWeek: Int = 1

    @AppStorage("tm_progression_style") private var tmProgStyleRaw: String = "classic"
    @AppStorage("auto_advance_week")    private var autoAdvanceWeek: Bool = false

    // NEW: User-selected assistance exercise IDs
    @AppStorage("assist_squat_id")    private var assistSquatID: String = "split_squat"
    @AppStorage("assist_bench_id")    private var assistBenchID: String = "triceps_ext"
    @AppStorage("assist_deadlift_id") private var assistDeadliftID: String = "back_ext"
    @AppStorage("assist_row_id")      private var assistRowID: String = "spider_curls"

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

    private let program = ProgramEngine()

    private var calculator: PlateCalculator {
        PlateCalculator(barWeight: barWeightForSelectedLift, roundTo: roundTo, inventory: [45, 35, 25, 10, 5, 2.5])
    }

    private var barWeightForSelectedLift: Double {
        implements.weight(for: selectedLift)
    }

    // MARK: - Small computed props to simplify body

    private var currentScheme: WeekSchemeResult { program.weekScheme(for: currentWeek) }
    private var tmSelected: Double { tmFor(selectedLift) }
    private var topWeight: Double {
        let pct = currentScheme.main.last?.pct ?? 0.85
        return calculator.round(tmSelected * pct)
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
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSettings = true } label: { Image(systemName: "gearshape") }
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
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsSheet(
                tmSquat: $tmSquat,
                tmBench: $tmBench,
                tmDeadlift: $tmDeadlift,
                tmRow: $tmRow,
                barWeight: $barWeight,
                roundTo: $roundTo,
                bbbPct: $bbbPct,
                timerRegularSec: $timerRegularSec,
                timerBBBsec: $timerBBBsec,
                tmProgStyleRaw: $tmProgStyleRaw,
                autoAdvanceWeek: $autoAdvanceWeek,
                assistSquatID: $assistSquatID,
                assistBenchID: $assistBenchID,
                assistDeadliftID: $assistDeadliftID,
                assistRowID: $assistRowID
            )
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showHistory) {
            HistorySheet()
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showGuide) {
            NavigationStack { UserGuideView() }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .interactiveDismissDisabled(false)
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
            liveRepsText = repsText(for: selectedLift)
        }
        .onChange(of: selectedLift) { _, new in
            liveRepsText = repsText(for: new)
        }
        .onChange(of: liveRepsText) { _, _ in
            saveReps(liveRepsText, for: selectedLift)
        }
    }

    // MARK: - Main scroll content (split out for compiler sanity)

    @ViewBuilder
    private var mainContent: some View {
        // compute metrics once
        let m = currentWorkoutMetrics()

        VStack(spacing: 16) {
            headerView

            TrainingMaxesLine(
                tmSquat: tmSquat,
                tmBench: tmBench,
                tmDeadlift: tmDeadlift,
                tmRow: tmRow
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
                label: selectedLift.label
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
                est1RM: { lift, w in est1RM(for: lift, weight: w) },
                setBinding: setBinding,
                liveRepsText: $liveRepsText,
                workoutState: workoutState
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
                assistSetBinding: assistSetBinding(_:)
            )

            SummaryCard(
                date: .now,
                est1RM: m.est,
                totals: (total: m.totalVol, main: m.mainVol, bbb: m.bbbVol, assist: m.assistVol)
            )

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
                    .padding(.horizontal)
            }
        }
    }

    private var finishButton: some View {
        Button {
            finishWorkout()
        } label: {
            Label("Finish Workout", systemImage: "checkmark.seal.fill")
                .font(.headline)
        }
        .buttonStyle(.borderedProminent)
    }

    private var resetButton: some View {
        Button(role: .destructive) {
            showResetConfirm = true
        } label: {
            Label("Reset Workout (Current Lift)", systemImage: "arrow.uturn.backward")
        }
    }

    // MARK: - Helpers

    private func assistanceExerciseFor(_ lift: Lift) -> AssistanceExercise {
        let id: String
        switch lift {
        case .squat:    id = assistSquatID
        case .bench:    id = assistBenchID
        case .deadlift: id = assistDeadliftID
        case .row:      id = assistRowID
        }
        return AssistanceExercise.byID(id) ?? AssistanceExercise.catalog.first!
    }

    private func tmFor(_ lift: Lift) -> Double {
        switch lift {
        case .squat: return tmSquat
        case .bench: return tmBench
        case .deadlift: return tmDeadlift
        case .row: return tmRow
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

        // Keep legacy per-lift default assistance weight baselines
        switch selectedLift {
        case .squat:    assistWeightSquat = 0
        case .bench:    assistWeightBench = 65
        case .deadlift: assistWeightDeadlift = 0
        case .row:      assistWeightRow = 0
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

    private func est1RM(for lift: Lift, weight: Double) -> Double {
        let reps = workoutState.getAMRAP(lift: lift.rawValue, week: currentWeek)
        guard reps > 0 else { return 0 }
        let est = weight * (1 + Double(reps) / 30.0)
        return calculator.round(est)
    }

    private func currentWorkoutMetrics() -> (est: Double, totalVol: Int, mainVol: Int, bbbVol: Int, assistVol: Int) {
        let scheme = program.weekScheme(for: currentWeek)
        let tmSel = tmFor(selectedLift)

        // MAIN sets
        func mainSetVol(_ idx: Int) -> Double {
            let s = scheme.main[idx]
            let w = calculator.round(tmSel * s.pct)
            let reps = s.amrap ? Double(max(workoutState.getAMRAP(lift: selectedLift.rawValue, week: currentWeek), 0)) : Double(s.reps)
            return w * reps
        }
        let mainVol = Int(mainSetVol(0) + mainSetVol(1) + mainSetVol(2))

        // BBB volume
        let defaultBBBW = calculator.round(tmSel * bbbPct)
        var bbbVol = 0.0
        for setNum in 1...5 {
            let mainSetNum = setNum + 3 // Sets 4-8
            if workoutState.getSetComplete(lift: selectedLift.rawValue, week: currentWeek, set: mainSetNum) {
                let weight = workoutState.getBBBWeight(lift: selectedLift.rawValue, week: currentWeek, set: setNum) ?? defaultBBBW
                let reps = workoutState.getBBBReps(lift: selectedLift.rawValue, week: currentWeek, set: setNum) ?? 10
                bbbVol += weight * Double(reps)
            }
        }

        // Assistance volume
        let ex = assistanceExerciseFor(selectedLift)
        let defaultAssistW = ex.defaultWeight > 0 ? ex.defaultWeight : (ex.allowWeightToggle && workoutState.getAssistUseWeight(lift: selectedLift.rawValue, week: currentWeek) ? ex.toggledWeight : 0)
        var assistVol = 0.0
        for setNum in 1...3 {
            if scheme.showBBB && workoutState.getAssistComplete(lift: selectedLift.rawValue, week: currentWeek, set: setNum) {
                let weight = workoutState.getAssistWeight(lift: selectedLift.rawValue, week: currentWeek, set: setNum) ?? defaultAssistW
                let reps = workoutState.getAssistReps(lift: selectedLift.rawValue, week: currentWeek, set: setNum) ?? ex.defaultReps
                assistVol += weight * Double(reps)
            }
        }

        let totalVol = Int(mainVol) + Int(bbbVol) + Int(assistVol)

        // Est 1RM
        let top = scheme.main[2]
        let est: Double = {
            guard top.amrap else { return 0 }
            let amrapReps = workoutState.getAMRAP(lift: selectedLift.rawValue, week: currentWeek)
            guard amrapReps > 0 else { return 0 }
            let w = calculator.round(tmSel * top.pct)
            let e = w * (1 + Double(amrapReps) / 30.0)
            return calculator.round(e)
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

        let entry = WorkoutEntry(
            date: .now,
            lift: selectedLift.label,
            est1RM: metrics.est,
            totalVolume: metrics.totalVol,
            bbbPct: bbbPct,
            amrapReps: workoutState.getAMRAP(lift: selectedLift.rawValue, week: currentWeek),
            notes: workoutNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : workoutNotes
        )
        WorkoutStore.shared.append(entry)

        timer.reset()
        workoutNotes = ""

        if autoAdvanceWeek {
            workoutState.markLiftComplete(selectedLift.rawValue, week: currentWeek)

            if workoutState.allLiftsComplete(for: currentWeek, totalLifts: Lift.allCases.count) {
                currentWeek = currentWeek % 4 + 1
                workoutState.resetCompletedLifts(for: currentWeek)
                savedAlertText += "\nAll lifts complete — advancing to Week \(currentWeek)!"
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
}
