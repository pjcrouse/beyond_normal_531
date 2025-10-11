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
                
                ScrollView {
                    VStack(spacing: 16) {
                        headerView
                        trainingMaxesView
                        quickTargetView
                        prDisclosureView
                        workoutBlockView
                        assistanceView
                        summaryView
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
    
    private var trainingMaxesView: some View {
        VStack(spacing: 6) {
            Text("Training Maxes (lb)").font(.headline)
            Text("SQ \(intOrDash(tmSquat))  •  BP \(intOrDash(tmBench))  •  DL \(intOrDash(tmDeadlift))  •  ROW \(intOrDash(tmRow))")
                .foregroundStyle(.secondary)
        }
    }
    
    private var quickTargetView: some View {
        let tmSel = tmFor(selectedLift)
        let scheme = program.weekScheme(for: currentWeek)
        let topPct = scheme.main.last?.pct ?? 0.85
        let topW = calculator.round(tmSel * topPct)
        
        return VStack(spacing: 4) {
            Text("Week \(currentWeek) • \(selectedLift.label)")
                .font(.headline)
            Text("\(scheme.topLine) → \(intOrDash(topW)) lb")
                .font(.title3.weight(.bold))
                .foregroundStyle(.blue)
        }
        .padding(.top, 6)
    }
    
    private var prDisclosureView: some View {
        let tmSel = tmFor(selectedLift)
        
        return DisclosureGroup(isExpanded: $showPRs) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Week 1: 85% × 5+ → \(int(calculator.round(tmSel * 0.85))) lb")
                Text("Week 2: 90% × 3+ → \(int(calculator.round(tmSel * 0.90))) lb")
                Text("Week 3: 95% × 1+ → \(int(calculator.round(tmSel * 0.95))) lb")
            }
            .padding(.top, 4)
        } label: {
            Text("PR sets • \(selectedLift.label)")
                .font(.headline)
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
            notesView
            timerView
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
    
    private var notesView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Workout Notes").font(.headline)
                Spacer()
                Text("saved with history").font(.caption).foregroundStyle(.secondary)
            }
            
            // Replace TextEditor with TextField for better performance
            TextField("Add notes about today's workout...", text: $workoutNotes, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(3...6)
                .padding(8)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                .autocorrectionDisabled()
                .focused($notesFocused)
                .onChange(of: workoutNotes) { _, newValue in
                    // Debounce to prevent excessive updates
                    notesDebounceTask?.cancel()
                    notesDebounceTask = Task {
                        try? await Task.sleep(nanoseconds: 300_000_000) // 0.3s
                        if !Task.isCancelled {
                            debouncedNotes = newValue
                        }
                    }
                }
        }
    }
    
    private var timerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Rest Timer").font(.headline)
                Spacer()
                Text(timer.isRunning ? "Running" : "Ready")
                    .font(.caption).foregroundStyle(.secondary)
            }
            
            Text(timer.remaining > 0 ? mmss(timer.remaining) :
                    "Ready (\(mmss(timerRegularSec)) / \(mmss(timerBBBsec)))")
            .font(.system(size: 34, weight: .bold, design: .rounded))
            
            HStack(spacing: 12) {
                Button {
                    timer.start(seconds: timerRegularSec)
                } label: { Label("Start Regular", systemImage: "timer") }
                
                Button {
                    timer.start(seconds: timerBBBsec)
                } label: { Label("Start BBB", systemImage: "timer") }
            }
            .buttonStyle(.bordered)
            
            HStack(spacing: 12) {
                Button(timer.isRunning ? "Pause" : "Resume") {
                    if timer.isRunning { timer.pause() }
                    else { timer.start(seconds: max(timer.remaining, 1)) }
                }
                .buttonStyle(.bordered)
                
                Button("Reset", role: .destructive) { timer.reset() }
                    .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
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
    
    private var summaryView: some View {
        let metrics = currentWorkoutMetrics()
        
        return Group {
            Divider().padding(.vertical, 8)
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Workout Summary").font(.headline)
                    Spacer()
                    Text(Date.now, style: .date).foregroundStyle(.secondary)
                }
                
                if metrics.est > 0 {
                    Text("Estimated 1RM: \(Int(metrics.est)) lb")
                } else {
                    Text("Estimated 1RM: —").foregroundStyle(.secondary)
                }
                
                Text("Total Volume: \(metrics.totalVol) lb")
                    .font(.subheadline.weight(.semibold))
                    .padding(.top, 2)
                
                Text("Main: \(metrics.mainVol) lb  •  BBB: \(metrics.bbbVol) lb  •  Assist: \(metrics.assistVol) lb")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
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
    
    private func mmss(_ s: Int) -> String {
        let m = s / 60, r = s % 60
        return String(format: "%d:%02d", m, r)
    }
    
    private func int(_ x: Double) -> String {
        x.rounded() == x ? String(format: "%.0f", x) : String(format: "%.1f", x)
    }
    
    private func intOrDash(_ x: Double) -> String {
        guard x.isFinite else { return "—" }
        return x.rounded() == x ? String(format: "%.0f", x) : String(format: "%.1f", x)
    }
    
    
    // MARK: - History Sheet
    
    private struct HistorySheet: View {
        @State private var entries: [WorkoutEntry] = []
        @State private var expanded: Set<UUID> = []
        
        // NEW: Weekly summary presentation state
        @State private var weeklyResult: WeeklySummaryResult? = nil
        
        var body: some View {
            NavigationStack {
                List {
                    if entries.isEmpty {
                        ContentUnavailableView("No saved workouts yet",
                                               systemImage: "tray",
                                               description: Text("Tap \"Finish Workout\" after a session to log it here."))
                    } else {
                        ForEach(entries.sorted(by: { $0.date > $1.date })) { e in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(e.lift).font(.headline)
                                    Spacer()
                                    Text(format(date: e.date))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                HStack(spacing: 16) {
                                    Text("Est 1RM \(Int(e.est1RM)) lb")
                                    Text("Volume \(e.totalVolume) lb")
                                }
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                                
                                HStack(spacing: 12) {
                                    Text("BBB \(Int(e.bbbPct * 100))%")
                                    Text("AMRAP \(e.amrapReps)")
                                }
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                
                                if let n = e.notes, !n.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                    Text(n)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(expanded.contains(e.id) ? nil : 2)
                                        .padding(.top, 2)
                                    
                                    Button(expanded.contains(e.id) ? "Show less" : "Show more") {
                                        if expanded.contains(e.id) { expanded.remove(e.id) } else { expanded.insert(e.id) }
                                    }
                                    .font(.caption)
                                    .buttonStyle(.plain)
                                    .padding(.top, 2)
                                }
                            }
                            .padding(.vertical, 4)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if expanded.contains(e.id) { expanded.remove(e.id) } else { expanded.insert(e.id) }
                            }
                            .contextMenu {
                                Button(role: .destructive) {
                                    delete(e)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                
                                // (optional) extras
                                Button {
                                    let formattedVolume = NumberFormatter.localizedString(from: NSNumber(value: e.totalVolume),
                                                                                          number: .decimal)
                                    let formatted1RM = NumberFormatter.localizedString(from: NSNumber(value: Int(e.est1RM)),
                                                                                       number: .decimal)
                                    let dateString = e.date.formatted(date: .abbreviated, time: .omitted)
                                    let summary = """
                                    \(e.lift): \(dateString)
                                    1RM \(formatted1RM) lb • Volume \(formattedVolume) lb
                                    """
                                    UIPasteboard.general.string = summary
                                } label: {
                                    Label("Copy summary", systemImage: "doc.on.doc")
                                }
                            }
                            .swipeActions {
                                Button(role: .destructive) {
                                    delete(e)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
                .navigationTitle("Saved Workouts")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            entries = WorkoutStore.shared.load().sorted { $0.date > $1.date }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                        .accessibilityLabel("Refresh")
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            let interval = currentCalendarWeekInterval()
                            let result = computeWeeklySummary(for: interval, entries: WorkoutStore.shared.load())
                            weeklyResult = result
                        } label: {
                            Image(systemName: "calendar.badge.checkmark")
                        }
                        .accessibilityLabel("Weekly Summary")
                    }
                }
                .onAppear {
                    entries = WorkoutStore.shared.load().sorted { $0.date > $1.date }
                }
                .sheet(item: $weeklyResult) { r in
                    WeeklySummarySheet(result: r)
                        .presentationDetents([.medium, .large])
                }
            }
        }
        
        private func format(date: Date) -> String {
            let f = DateFormatter()
            f.dateStyle = .medium
            f.timeStyle = .short
            return f.string(from: date)
        }
        
        private func delete(_ entry: WorkoutEntry) {
            WorkoutStore.shared.delete(id: entry.id)
            entries.removeAll { $0.id == entry.id }
        }
    }
    
    // MARK: - Weekly Summary Sheet
    
    private struct WeeklySummarySheet: View {
        let result: WeeklySummaryResult
        
        var body: some View {
            NavigationStack {
                List {
                    Section(header: Text("Totals")) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Week:")
                            Text("\(formatDate(result.interval.start)) – \(formatDate(result.interval.end.addingTimeInterval(-1)))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("Total Volume: \(result.totalVolume.formatted(.number)) lb")
                                .font(.headline)
                        }
                    }
                    Section(header: Text("Estimated 1RMs")) {
                        if result.oneRMs.isEmpty {
                            Text("No AMRAP sets logged this week.")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(result.oneRMs.indices, id: \.self) { i in
                                let item = result.oneRMs[i]
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(item.lift).font(.headline)
                                        Text(formatDateTime(item.date))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Text("\(item.est1RM) lb")
                                        .font(.headline)
                                }
                            }
                        }
                    }
                }
                .navigationTitle("Weekly Summary")
            }
        }
        
        private func formatDate(_ d: Date) -> String {
            let f = DateFormatter()
            f.dateStyle = .medium
            f.timeStyle = .none
            return f.string(from: d)
        }
        private func formatDateTime(_ d: Date) -> String {
            let f = DateFormatter()
            f.dateStyle = .medium
            f.timeStyle = .short
            return f.string(from: d)
        }
    }
    
    // MARK: - Exercise Picker
    
    private struct ExercisePickerView: View {
        let title: String
        @Binding var selectedID: String
        let allowedCategories: [ExerciseCategory]
        
        @State private var query: String = ""
        
        private var filtered: [AssistanceExercise] {
            AssistanceExercise.catalog
                .filter { allowedCategories.contains($0.category) }
                .filter { query.isEmpty || $0.name.localizedCaseInsensitiveContains(query) }
                .sorted { $0.name < $1.name }
        }
        
        var body: some View {
            List {
                if filtered.isEmpty {
                    ContentUnavailableView("No matches",
                                           systemImage: "magnifyingglass",
                                           description: Text("Try a different search term."))
                } else {
                    ForEach(filtered) { ex in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(ex.name).font(.body)
                                Text(ex.category.rawValue.capitalized)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if selectedID == ex.id {
                                Image(systemName: "checkmark.circle.fill")
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { selectedID = ex.id }
                    }
                }
            }
            .navigationTitle(title)
            .searchable(text: $query, placement: .navigationBarDrawer)
        }
    }
    
    // MARK: - Settings Sheet
    
    private struct SettingsSheet: View {
        @Binding var tmSquat: Double
        @Binding var tmBench: Double
        @Binding var tmDeadlift: Double
        @Binding var tmRow: Double
        @Binding var barWeight: Double
        @Binding var roundTo: Double
        @Binding var bbbPct: Double
        @Binding var timerRegularSec: Int
        @Binding var timerBBBsec: Int
        @Binding var tmProgStyleRaw: String
        @Binding var autoAdvanceWeek: Bool
        
        // Assistance exercise selections
        @Binding var assistSquatID: String
        @Binding var assistBenchID: String
        @Binding var assistDeadliftID: String
        @Binding var assistRowID: String
        
        @State private var tmpSquat = ""
        @State private var tmpBench = ""
        @State private var tmpDeadlift = ""
        @State private var tmpRow = ""
        @State private var tmpBarWeight = ""
        @State private var tmpRoundTo = ""
        @State private var tmpTimerRegular = ""
        @State private var tmpTimerBBB = ""
        
        @Environment(\.dismiss) private var dismiss
        @FocusState private var focusedField: Field?
        
        enum Field {
            case squat, bench, deadlift, row, barWeight, roundTo, timerRegular, timerBBB
        }
        
        var body: some View {
            NavigationStack {
                Form {
                    Section("Training Maxes (lb)") {
                        numField("Squat", value: $tmpSquat, field: .squat)
                        numField("Bench", value: $tmpBench, field: .bench)
                        numField("Deadlift", value: $tmpDeadlift, field: .deadlift)
                        numField("Row", value: $tmpRow, field: .row)
                    }
                    
                    Section("Loading") {
                        numField("Default Bar Weight (lb)", value: $tmpBarWeight, field: .barWeight)
                        numField("Round To (lb)", value: $tmpRoundTo, field: .roundTo)
                        Text("Tip: Per-exercise implements override the default for plate math.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Section("Assistance (BBB)") {
                        HStack {
                            Text("BBB % of TM")
                            Spacer()
                            Text("\(Int(bbbPct * 100))%")
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: $bbbPct, in: 0.50...0.70, step: 0.05)
                    }
                    
                    Section("Rest Timer (seconds)") {
                        HStack {
                            Text("Regular sets")
                            Spacer()
                            TextField("240", text: $tmpTimerRegular)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .focused($focusedField, equals: .timerRegular)
                        }
                        HStack {
                            Text("BBB / accessory")
                            Spacer()
                            TextField("180", text: $tmpTimerBBB)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .focused($focusedField, equals: .timerBBB)
                        }
                        Text("Tip: 240s = 4:00, 180s = 3:00")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Section("TM Progression Style") {
                        Picker("Style", selection: $tmProgStyleRaw) {
                            Text("Classic (+5/+10)").tag("classic")
                            Text("Auto (90% of AMRAP 1RM)").tag("auto")
                        }
                        .pickerStyle(.segmented)
                        Text("Classic = steady +5 upper / +10 lower per cycle.\nAuto = set TM to 90% of latest AMRAP est. 1RM (capped at +10 upper / +20 lower).")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Section("Assistance Exercises") {
                        NavigationLink("Squat Day") {
                            ExercisePickerView(
                                title: "Choose Squat Assistance",
                                selectedID: $assistSquatID,
                                allowedCategories: [.legs]
                            )
                        }
                        NavigationLink("Bench Day") {
                            ExercisePickerView(
                                title: "Choose Bench Assistance",
                                selectedID: $assistBenchID,
                                allowedCategories: [.push]
                            )
                        }
                        NavigationLink("Deadlift Day") {
                            ExercisePickerView(
                                title: "Choose Deadlift Assistance",
                                selectedID: $assistDeadliftID,
                                allowedCategories: [.legs, .core]
                            )
                        }
                        NavigationLink("Row Day") {
                            ExercisePickerView(
                                title: "Choose Row Assistance",
                                selectedID: $assistRowID,
                                allowedCategories: [.pull]
                            )
                        }
                        
                        Button {
                            // Restore recommended defaults
                            assistSquatID = "split_squat"
                            assistBenchID = "triceps_ext"
                            assistDeadliftID = "back_ext"
                            assistRowID = "spider_curls"
                        } label: {
                            Label("Restore Recommended", systemImage: "arrow.counterclockwise")
                        }
                    }
                    
                    Section("Implements") {
                        NavigationLink("Configure Implements") {
                            ImplementsEditorView()
                        }
                        Text("Set per-exercise bar/EZ implement weights for plate math.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Section("Behavior") {
                        Toggle("Auto-advance week after finishing workout", isOn: $autoAdvanceWeek)
                    }
                    
                    Section {
                        Button(role: .destructive) {
                            tmpSquat = "315"; tmpBench = "225"
                            tmpDeadlift = "405"; tmpRow = "185"
                            tmpBarWeight = "45"; tmpRoundTo = "5"
                            tmpTimerRegular = "240"; tmpTimerBBB = "180"
                            ImplementWeights.shared.restoreDefaults()
                        } label: {
                            Label("Reset to defaults", systemImage: "arrow.counterclockwise")
                        }
                    }
                    Section("Help & Support") {
                        NavigationLink("User Guide 📖") {
                            UserGuideView()
                        }
                        Link("Send Feedback Email", destination: URL(string: "mailto:support@beyondnormal.app")!)
                    }
                }
                .toolbar {
                    if focusedField != nil {
                        ToolbarItemGroup(placement: .keyboard) {
                            Spacer()
                            Button("Done") { focusedField = nil }
                        }
                    }
                }
                .navigationTitle("Settings")
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Cancel") { dismiss() }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Save") {
                            if let v = Double(tmpSquat)    { tmSquat = v }
                            if let v = Double(tmpBench)    { tmBench = v }
                            if let v = Double(tmpDeadlift) { tmDeadlift = v }
                            if let v = Double(tmpRow)      { tmRow = v }
                            if let v = Double(tmpBarWeight){ barWeight = max(1,   min(v, 200)) }
                            if let v = Double(tmpRoundTo)  { roundTo   = max(0.5, min(v, 100)) }
                            if let v = Int(tmpTimerRegular) { timerRegularSec = max(1, v) }
                            if let v = Int(tmpTimerBBB)     { timerBBBsec     = max(1, v) }
                            dismiss()
                        }.bold()
                    }
                }
                .onAppear {
                    tmpSquat = String(format: "%.0f", tmSquat)
                    tmpBench = String(format: "%.0f", tmBench)
                    tmpDeadlift = String(format: "%.0f", tmDeadlift)
                    tmpRow = String(format: "%.0f", tmRow)
                    tmpBarWeight = String(format: "%.0f", barWeight)
                    tmpRoundTo = String(format: "%.0f", roundTo)
                    tmpTimerRegular = String(timerRegularSec)
                    tmpTimerBBB = String(timerBBBsec)
                }
            }
        }
        
        @ViewBuilder
        private func numField(_ label: String, value: Binding<String>, field: Field) -> some View {
            HStack {
                Text(label)
                Spacer()
                TextField("0", text: value)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 100)
                    .focused($focusedField, equals: field)
            }
        }
    }
    
    // MARK: - Implements Editor (no UIKit keyboard toolbar; stable + fast)
    
    private struct ImplementsEditorView: View {
        @ObservedObject private var impl = ImplementWeights.shared
        @State private var q: String = ""
        
        // Inline editing state
        @State private var editingID: String? = nil
        @State private var editingText: String = ""
        @FocusState private var editingFocused: Bool
        
        // Constraints / options
        private let minW = 1.0
        private let maxW = 200.0
        private let isDecimalAllowed = false // set true if you want 2.5 etc.
        
        // Which implements are editable
        private var items: [(id: String, name: String)] {
            let mains: [(String,String)] = [
                ("SQ","Squat (Main)"),
                ("BP","Bench (Main)"),
                ("DL","Deadlift (Main)"),
                ("RW","Row (Main)")
            ]
            let bars = AssistanceExercise.catalog
                .filter { ["front_squat", "paused_squat", "close_grip", "triceps_ext"].contains($0.id) }
                .map { ($0.id, $0.name) }
            return (mains + bars)
                .filter { q.isEmpty || $0.1.localizedCaseInsensitiveContains(q) }
                .sorted { $0.1 < $1.1 }
        }
        
        var body: some View {
            List {
                Section(footer: Text("Changes save automatically.")
                    .font(.caption)
                    .foregroundStyle(.secondary)) {
                        ForEach(items, id: \.id) { item in
                            let id = item.id
                            let current = impl.weight(for: id)
                            
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(item.name)
                                    Spacer()
                                    
                                    if editingID == id {
                                        // Inline numeric field (fixed width so it never collapses to 0)
                                        TextField("", text: $editingText)
                                            .keyboardType(isDecimalAllowed ? .decimalPad : .numberPad)
                                            .textFieldStyle(.roundedBorder)
                                            .frame(width: 96) // fixed avoids transient zero width
                                            .monospacedDigit()
                                            .focused($editingFocused)
                                            .submitLabel(.done)
                                            .onSubmit { commitInlineEdit(for: id) }
                                            .onChange(of: editingText) { _, t in
                                                let filtered = filteredNumericString(t, allowDecimal: isDecimalAllowed)
                                                if filtered != t { editingText = filtered }
                                            }
                                    } else {
                                        // Current value (tap to edit)
                                        Button {
                                            editingText = displayString(for: current, decimals: isDecimalAllowed)
                                            editingID = id // focus toggled in .onChange below
                                        } label: {
                                            Text("\(displayString(for: current, decimals: isDecimalAllowed)) lb")
                                                .font(.callout)
                                                .monospacedDigit()
                                                .foregroundStyle(.secondary)
                                        }
                                        .buttonStyle(.plain)
                                        .accessibilityLabel("\(item.name) weight, \(Int(current)) pounds, tap to edit")
                                    }
                                }
                                
                                // Stepper for small nudges
                                Stepper(value: Binding(
                                    get: { Int(impl.weight(for: id)) },
                                    set: { impl.setWeight(clamp(Double($0)), for: id) }
                                ), in: Int(minW)...Int(maxW)) {
                                    Text("Adjust")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                // Per-row reset
                                if Int(current) != Int(defaultFor(id)) {
                                    Button {
                                        impl.setWeight(defaultFor(id), for: id)
                                    } label: {
                                        Label("Reset to default (\(Int(defaultFor(id))) lb)", systemImage: "arrow.counterclockwise")
                                    }
                                    .buttonStyle(.borderless)
                                    .font(.caption)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                
                Section {
                    Button {
                        impl.restoreDefaults()
                    } label: {
                        Label("Restore All Defaults", systemImage: "arrow.counterclockwise")
                    }
                }
            }
            .navigationTitle("Implements")
            .searchable(text: $q)
            
            // Focus management: only toggle here (keeps layout calm)
            .onChange(of: editingID) { _, newID in
                if newID != nil {
                    DispatchQueue.main.async { editingFocused = true }
                } else {
                    editingFocused = false
                }
            }
            
            // Our own "Done" bar above the keyboard — no UIKit toolbar involved
            .safeAreaInset(edge: .bottom) {
                if editingFocused {
                    HStack {
                        Spacer()
                        Button {
                            if let id = editingID { commitInlineEdit(for: id) }
                            resignKeyboard()
                        } label: {
                            Label("Done", systemImage: "keyboard.chevron.compact.down")
                                .font(.body.weight(.semibold))
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 8) // sits just above keyboard
                    .background(.ultraThinMaterial)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.default, value: editingFocused)
        }
        
        // MARK: - Helpers
        
        private func commitInlineEdit(for id: String) {
            let v = parsedNumber(from: editingText, allowDecimal: isDecimalAllowed)
            let clamped = clamp(v ?? impl.weight(for: id))
            impl.setWeight(clamped, for: id)
            editingID = nil
            editingText = ""
        }
        
        private func clamp(_ x: Double) -> Double { max(minW, min(x, maxW)) }
        
        private func displayString(for x: Double, decimals: Bool) -> String {
            decimals
            ? String(format: x.rounded() == x ? "%.0f" : "%.1f", x)
            : String(format: "%.0f", x)
        }
        
        private func filteredNumericString(_ s: String, allowDecimal: Bool) -> String {
            if allowDecimal {
                var seenDot = false
                return s.filter { c in
                    if c.isNumber { return true }
                    if c == "." && !seenDot { seenDot = true; return true }
                    return false
                }
            } else {
                return s.filter(\.isNumber)
            }
        }
        
        private func parsedNumber(from s: String, allowDecimal: Bool) -> Double? {
            allowDecimal ? Double(s) : Double(Int(s) ?? 0)
        }
        
        private func defaultFor(_ id: String) -> Double {
            let defaults: [String: Double] = [
                "SQ": 75, "BP": 45, "DL": 45, "RW": 45,
                "front_squat": 45, "paused_squat": 45, "close_grip": 45, "triceps_ext": 25
            ]
            return defaults[id] ?? 45
        }
        
        private func resignKeyboard() {
#if canImport(UIKit)
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
#endif
        }
    }
}
