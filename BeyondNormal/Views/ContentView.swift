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
    
    // Assistance defaults (kept for legacy; current UI uses per-exercise defaults)
    @AppStorage("assist_weight_squat")    private var assistWeightSquat: Double = 0
    @AppStorage("assist_weight_bench")    private var assistWeightBench: Double = 65
    @AppStorage("assist_weight_deadlift") private var assistWeightDeadlift: Double = 0
    @AppStorage("assist_weight_row")      private var assistWeightRow: Double = 0
    
    @AppStorage("timer_regular_sec") private var timerRegularSec: Int = 240
    @AppStorage("timer_bbb_sec")     private var timerBBBsec: Int = 180
    @AppStorage("current_week")      private var currentWeek: Int = 1
    
    @AppStorage("tm_progression_style") private var tmProgStyleRaw: String = "classic"
    @AppStorage("auto_advance_week")    private var autoAdvanceWeek: Bool = false
    
    // NEW: User-selected assistance exercise IDs (backward-compatible defaults)
    @AppStorage("assist_squat_id")    private var assistSquatID: String = "split_squat"
    @AppStorage("assist_bench_id")    private var assistBenchID: String = "triceps_ext"
    @AppStorage("assist_deadlift_id") private var assistDeadliftID: String = "back_ext"
    @AppStorage("assist_row_id")      private var assistRowID: String = "spider_curls"
    
    @StateObject private var workoutState = WorkoutStateManager()
    @StateObject private var timer = TimerManager()
    @StateObject private var implements = ImplementWeights.shared
    
    @State private var workoutNotes: String = ""
    @State private var debouncedNotes: String = ""
    @State private var savedAlertText = ""
    @State private var showSettings = false
    @State private var showPRs = false
    @State private var selectedLift: Lift = .bench
    @State private var liveRepsText: String = ""
    @State private var showResetConfirm = false
    @State private var showSavedAlert = false
    @State private var showHistory = false
    @State private var notesDebounceTask: Task<Void, Never>?
    @FocusState private var amrapFocused: Bool
    @FocusState private var notesFocused: Bool
    
    @State private var showGuide = false
    
    private let program = ProgramEngine()
    
    private var calculator: PlateCalculator {
        PlateCalculator(barWeight: barWeightForSelectedLift, roundTo: roundTo, inventory: [45, 35, 25, 10, 5, 2.5])
    }
    
    private var barWeightForSelectedLift: Double {
        // Per-exercise implement; falls back to defaults in ImplementWeights
        implements.weight(for: selectedLift)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color(.systemBackground), Color(.secondarySystemBackground)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // compute once for header + PR disclosure below
                let tmSel   = tmFor(selectedLift)
                let scheme  = program.weekScheme(for: currentWeek)
                let topPct  = scheme.main.last?.pct ?? 0.85
                let topW    = calculator.round(tmSel * topPct)
                
                ScrollView {
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
                            topLine: scheme.topLine,
                            topWeight: topW
                        )
                        PRDisclosureView(
                            expanded: $showPRs,
                            tm: tmSel,
                            rounder: { calculator.round($0) },
                            label: selectedLift.label
                        )
                        workoutBlockView
                        assistanceView
                        let m = currentWorkoutMetrics()
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
            }
            .navigationTitle("5/3/1 • Beyond Normal")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showHistory = true
                    } label: {
                        Label("History", systemImage: "clock.arrow.circlepath")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showGuide = true } label: {
                        Image(systemName: "questionmark.circle")
                    }
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
            NavigationStack {
                UserGuideView()
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .interactiveDismissDisabled(false)
        }
        .alert("Reset current lift?", isPresented: $showResetConfirm) {
            Button("Reset", role: .destructive) {
                resetCurrentLift()
            }
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
        .onChange(of: liveRepsText) { _, new in
            saveReps(new, for: selectedLift)
        }
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
    
    private var workoutBlockView: some View {
        let tm = tmFor(selectedLift)
        let scheme = program.weekScheme(for: currentWeek)
        
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Week \(currentWeek) Workout")
                    .font(.title3.weight(.bold))
                Spacer()
                Picker("Week", selection: $currentWeek) {
                    Text("1").tag(1); Text("2").tag(2); Text("3").tag(3); Text("4").tag(4);
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 220)
            }
            
            Picker("Lift", selection: $selectedLift) {
                ForEach(Lift.allCases) { Text($0.label).tag($0) }
            }
            .pickerStyle(.segmented)
            
            // >>> Warmup Guidance button (always visible, including deload week)
            let firstSet = calculator.round(tm * scheme.main[0].pct)
            NavigationLink {
                WarmupGuideView(
                    lift: selectedLift,
                    targetWeight: firstSet,
                    barWeight: barWeightForSelectedLift,
                    roundTo: roundTo,
                    calculator: calculator
                )
            } label: {
                Label("Warmup Guidance", systemImage: "flame")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
            
            mainSetsView(tm: tm, scheme: scheme)
            NotesField(text: $workoutNotes, focused: _notesFocused)
            RestTimerCard(timer: timer, regular: timerRegularSec, bbb: timerBBBsec)
            bbbSetsView(tm: tm, scheme: scheme)
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }
    
    private func mainSetsView(tm: Double, scheme: WeekSchemeResult) -> some View {
        let s0 = scheme.main[0], s1 = scheme.main[1], s2 = scheme.main[2]
        let w0 = calculator.round(tm * s0.pct)
        let w1 = calculator.round(tm * s1.pct)
        let w2 = calculator.round(tm * s2.pct)
        
        return Group {
            SetRow(
                label: "\(Int(s0.pct * 100))% × \(s0.reps)",
                weight: w0,
                perSide: calculator.plates(target: w0),
                done: setBinding(1),
                onCheck: { checked in if checked { timer.start(seconds: timerRegularSec) } }
            )
            
            SetRow(
                label: "\(Int(s1.pct * 100))% × \(s1.reps)",
                weight: w1,
                perSide: calculator.plates(target: w1),
                done: setBinding(2),
                onCheck: { checked in if checked { timer.start(seconds: timerRegularSec) } }
            )
            
            if s2.amrap {
                AMRAPRow(
                    label: "\(Int(s2.pct * 100))% × \(s2.reps)+",
                    weight: w2,
                    perSide: calculator.plates(target: w2),
                    done: setBinding(3),
                    reps: $liveRepsText,
                    est1RM: est1RM(for: selectedLift, weight: w2),
                    onCheck: { checked in if checked { timer.start(seconds: timerRegularSec) } },
                    focus: $amrapFocused
                )
            } else {
                SetRow(
                    label: "\(Int(s2.pct * 100))% × \(s2.reps)",
                    weight: w2,
                    perSide: calculator.plates(target: w2),
                    done: setBinding(3),
                    onCheck: { checked in if checked { timer.start(seconds: timerRegularSec) } }
                )
                Text("Deload week: skip BBB/assistance and add 10–20 min easy cardio.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private func bbbSetsView(tm: Double, scheme: WeekSchemeResult) -> some View {
        Group {
            if scheme.showBBB {
                Divider().padding(.vertical, 4)
                let defaultBBBWeight = calculator.round(tm * bbbPct)
                
                Text(selectedLift == .row
                     ? "Assistance — Lat Pulldown 5×10 @ \(Int(bbbPct * 100))% TM (Row)"
                     : "Assistance — BBB 5×10 @ \(Int(bbbPct * 100))% TM")
                .font(.headline)
                
                ForEach(1...5, id: \.self) { bbbSetNum in
                    let setNum = bbbSetNum + 3 // Sets 4-8 in the main tracking
                    BBBSetRow(
                        setNumber: bbbSetNum,
                        defaultWeight: defaultBBBWeight,
                        defaultReps: 10,
                        done: setBinding(setNum),
                        currentWeight: Binding(
                            get: { workoutState.getBBBWeight(lift: selectedLift.rawValue, week: currentWeek, set: bbbSetNum) ?? defaultBBBWeight },
                            set: { newVal in
                                if abs(newVal - defaultBBBWeight) < 0.1 {
                                    workoutState.setBBBWeight(lift: selectedLift.rawValue, week: currentWeek, set: bbbSetNum, weight: nil)
                                } else {
                                    workoutState.setBBBWeight(lift: selectedLift.rawValue, week: currentWeek, set: bbbSetNum, weight: newVal)
                                }
                            }
                        ),
                        currentReps: Binding(
                            get: { workoutState.getBBBReps(lift: selectedLift.rawValue, week: currentWeek, set: bbbSetNum) ?? 10 },
                            set: { newVal in
                                if newVal == 10 {
                                    workoutState.setBBBReps(lift: selectedLift.rawValue, week: currentWeek, set: bbbSetNum, reps: nil)
                                } else {
                                    workoutState.setBBBReps(lift: selectedLift.rawValue, week: currentWeek, set: bbbSetNum, reps: newVal)
                                }
                            }
                        ),
                        perSide: (selectedLift == .row) ? [] : calculator.plates(target: workoutState.getBBBWeight(lift: selectedLift.rawValue, week: currentWeek, set: bbbSetNum) ?? defaultBBBWeight),
                        roundTo: roundTo,
                        onCheck: { checked in if checked { timer.start(seconds: timerBBBsec) } }
                    )
                }
            } else {
                Text("Deload week: skip BBB/assistance and add ~30 min easy cardio.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private var assistanceView: some View {
        let scheme = program.weekScheme(for: currentWeek)
        let ex = assistanceExerciseFor(selectedLift)
        
        // Decide if this assistance uses a barbell implement (to show plates)
        let barAssistanceIDs: Set<String> = ["front_squat", "paused_squat", "close_grip"]
        let usesBarbell = barAssistanceIDs.contains(ex.id)
        let implementW = implements.weight(for: ex.id)
        
        return Group {
            if scheme.showBBB {
                Divider().padding(.vertical, 6)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Assistance — \(ex.name)")
                        .font(.headline)
                    
                    // Add toggle ONLY if allowWeightToggle is true
                    if ex.allowWeightToggle {
                        Toggle(isOn: Binding(
                            get: { workoutState.getAssistUseWeight(lift: selectedLift.rawValue, week: currentWeek) },
                            set: { workoutState.setAssistUseWeight(lift: selectedLift.rawValue, week: currentWeek, useWeight: $0) }
                        )) {
                            Text("Use dumbbells")
                                .font(.subheadline)
                        }
                        .toggleStyle(.switch)
                    }
                }
                
                // Determine if weight is used: either defaultWeight > 0 OR toggle is on
                let useWeight = ex.defaultWeight > 0 || (ex.allowWeightToggle && workoutState.getAssistUseWeight(lift: selectedLift.rawValue, week: currentWeek))
                let defaultWeight = ex.defaultWeight > 0 ? ex.defaultWeight : (ex.allowWeightToggle && workoutState.getAssistUseWeight(lift: selectedLift.rawValue, week: currentWeek) ? ex.toggledWeight : 0)
                
                ForEach(1...3, id: \.self) { setNum in
                    // current set weight value
                    let currentW = workoutState.getAssistWeight(lift: selectedLift.rawValue, week: currentWeek, set: setNum) ?? defaultWeight
                    AssistSetRow(
                        setNumber: setNum,
                        defaultWeight: defaultWeight,
                        defaultReps: ex.defaultReps,
                        hasBarWeight: useWeight,
                        usesBarbell: usesBarbell,
                        done: assistSetBinding(setNum),
                        currentWeight: Binding(
                            get: { workoutState.getAssistWeight(lift: selectedLift.rawValue, week: currentWeek, set: setNum) ?? defaultWeight },
                            set: { newVal in
                                if abs(newVal - defaultWeight) < 0.1 {
                                    workoutState.setAssistWeight(lift: selectedLift.rawValue, week: currentWeek, set: setNum, weight: nil)
                                } else {
                                    workoutState.setAssistWeight(lift: selectedLift.rawValue, week: currentWeek, set: setNum, weight: newVal)
                                }
                            }
                        ),
                        currentReps: Binding(
                            get: { workoutState.getAssistReps(lift: selectedLift.rawValue, week: currentWeek, set: setNum) ?? ex.defaultReps },
                            set: { newVal in
                                if newVal == ex.defaultReps {
                                    workoutState.setAssistReps(lift: selectedLift.rawValue, week: currentWeek, set: setNum, reps: nil)
                                } else {
                                    workoutState.setAssistReps(lift: selectedLift.rawValue, week: currentWeek, set: setNum, reps: newVal)
                                }
                            }
                        ),
                        perSide: (usesBarbell && useWeight)
                        ? calculator.plates(target: currentW, barWeight: implementW)
                        : [],
                        roundTo: roundTo,
                        onCheck: { checked in
                            if checked { timer.start(seconds: timerBBBsec) }
                        }
                    )
                }
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
    
    private func int(_ x: Double) -> String {
        x.rounded() == x ? String(format: "%.0f", x) : String(format: "%.1f", x)
    }
    
    private func intOrDash(_ x: Double) -> String {
        guard x.isFinite else { return "—" }
        return x.rounded() == x ? String(format: "%.0f", x) : String(format: "%.1f", x)
    }
}
