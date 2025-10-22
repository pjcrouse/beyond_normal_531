import SwiftUI
import Foundation
import Combine
import UserNotifications
import UIKit

extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
// MARK: - Main View

struct ContentView: View {
    @EnvironmentObject private var settings: ProgramSettings
    // Training inputs
    private var roundTo: Double { settings.roundTo }
    private var bbbPct: Double { settings.bbbPercent }
    private var timerRegularSec: Int { settings.timerRegularSec }
    private var timerBBBsec: Int { settings.timerBBBSec }
    private var autoAdvanceWeek: Bool { settings.autoAdvanceWeek }
    
    
    // Assistance defaults (legacy)
    @AppStorage("assist_weight_squat")    private var assistWeightSquat: Double = 0
    @AppStorage("assist_weight_bench")    private var assistWeightBench: Double = 65
    @AppStorage("assist_weight_deadlift") private var assistWeightDeadlift: Double = 0
    @AppStorage("assist_weight_row")      private var assistWeightRow: Double = 0
    
    @AppStorage("current_week")      private var currentWeek: Int = 1
    
    // Configurable workouts per week support (now sourced from ProgramSettings)
    private var workoutsPerWeek: Int { settings.workoutsPerWeek }   // 3, 4, or 5
    private var fourthLift: Lift {
            settings.fourthLiftRaw.lowercased() == "press" ? .press : .row
        }
    
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
    @State private var showDataManagement = false
    @FocusState private var amrapFocused: Bool
    @FocusState private var notesFocused: Bool
    
    @State private var showGuide = false
    
    // Gate that views check before calling timer.start(...)
    @State private var allowTimerStarts = false
    
    @State private var showPRsSheet = false
    
    // Library for assistance lookup (still needed for selected exercise resolution)
    @EnvironmentObject private var assistanceLibrary: AssistanceLibrary
    
    @State private var prService = PRService()
    @StateObject private var awardStore = AwardStore()
    
    // If you already store the user’s display name somewhere, use that.
    // For now, a placeholder:
    @AppStorage("user_display_name") private var userDisplayName: String = ""
    
    // Workout/cycle completion
    @State private var toastText: String?
    @State private var showToast: Bool = false
    
    @State private var showCycleSummary = false
    @State private var cycleSummaryLines: [String] = []
    @State private var cycleAdvancedFrom: Int = 1
    
    @State private var weightsVersion = 0
    
    @StateObject private var tour = TourController()
    @State private var tourTargets: [TourTargetID: Anchor<CGRect>] = [:]
    
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
        case .squat: return settings.tmSquat
        case .bench: return settings.tmBench
        case .deadlift: return settings.tmDeadlift
        case .row: return settings.tmRow
        case .press: return settings.tmPress
        }
    }
    
    private func setTM(_ lift: Lift, _ value: Double) {
        let v = max(45, value.rounded())  // keep sane & whole lbs
        switch lift {
        case .squat: settings.tmSquat = v
        case .bench: settings.tmBench = v
        case .deadlift: settings.tmDeadlift = v
        case .row: settings.tmRow = v
        case .press: settings.tmPress = v
        }
    }
    
    // Returns per-lift TM change lines you can show in a toast.
    private func applyTMProgressionForNewCycle(from oldCycle: Int) -> [String] {
        var lines: [String] = []

        // Capture pre-bump values for just the lifts you’ll progress
        let liftsToProgress = activeLifts
        let before: [Lift: Double] = [
            .squat: settings.tmSquat, .bench: settings.tmBench, .deadlift: settings.tmDeadlift, .row: settings.tmRow, .press: settings.tmPress
        ]

        switch settings.progressionStyle {
        case .classic:
            for lift in liftsToProgress {
                let bumped = getTM(lift) + classicBumpAmount(for: lift)
                setTM(lift, bumped)
            }

        case .auto:
            for lift in liftsToProgress {
                // Best est-1RM recorded THIS cycle for this lift
                let best = PRStore.shared.bestByCycle[PRKey(cycle: oldCycle, lift: lift.label)] ?? 0
                guard best > 0 else { continue }

                // Use the user’s percent instead of hardcoded 90
                let targetTM = (Double(best) * Double(settings.autoTMPercent) / 100.0).rounded()
                let currentTM = getTM(lift)

                // Cap the increase per cycle
                let maxUp = autoMaxDelta(for: lift)
                let delta = min(max(targetTM - currentTM, 0), maxUp)

                setTM(lift, currentTM + delta)
            }
        }

        // Build change lines for the lifts we progressed
        for lift in liftsToProgress {
            if let old = before[lift] {
                lines.append( tmChangeLine(lift.label, old, getTM(lift)) )
            }
        }
        return lines
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
        GeometryReader { proxy in
            ZStack {
                // === YOUR EXISTING CONTENT (unchanged) ===
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
                            .labelStyle(.iconOnly)
                            .tint(Color.brandAccent)
                            .accessibilityLabel("History")
                        }
                        ToolbarItem(placement: .topBarLeading) {
                            Button { showDataManagement = true } label: {
                                Label("Data", systemImage: "externaldrive.fill")
                            }
                            .tint(Color.brandAccent)
                            .accessibilityLabel("Data Management")
                        }
                        
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                showSettings = true
                                // If we were highlighting the gear, advance the tour into the sheet
                                if tour.isActive, tour.currentTarget == .settingsGear {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.10) {
                                        tour.go(to: .displayName)
                                    }
                                }
                            } label: {
                                Image(systemName: "gearshape")
                            }
                            .accessibilityLabel("Settings")
                            .tourTarget(id: .settingsGear)
                        }
                        
                        ToolbarItem(placement: .topBarTrailing) {
                            Button { showGuide = true } label: { Image(systemName: "questionmark.circle") }
                                .accessibilityLabel("User Guide")
                                .tourTarget(id: .helpIcon)
                        }
                        ToolbarItem(placement: .topBarTrailing) {
                            Button { showPRsSheet = true } label: { Image(systemName: "trophy.fill") }
                                .accessibilityLabel("PRs")
                        }
                    }
                    .overlay(alignment: .top) {
                        if showToast, let text = toastText {
                            Toast(text: text)
                                .transition(.move(edge: .top).combined(with: .opacity))
                                .onAppear {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                        withAnimation { showToast = false }
                                    }
                                }
                                .padding(.top, 8)
                                .padding(.horizontal)
                        }
                    }
                }
                .tint(Color.brandAccent)
                .sheet(isPresented: $showSettings) {
                    SettingsSheet()
                        .environmentObject(settings)
                        .environmentObject(tour)  
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
                .sheet(isPresented: $showDataManagement) {
                    DataManagementView()
                        .presentationDetents([.medium, .large])
                }
                .sheet(isPresented: $showCycleSummary) {
                    CycleSummaryView(
                        fromCycle: cycleAdvancedFrom,
                        toCycle: currentCycle,
                        style: settings.progressionStyle,
                        lines: cycleSummaryLines
                    )
                    .presentationDetents([.medium, .large])
                    .preferredColorScheme(.dark)
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
                .safeAreaInset(edge: .bottom) {
                    if notesFocused || amrapFocused {
                        HStack {
                            Spacer()
                            Button {
                                amrapFocused = false
                                notesFocused = false
                                UIApplication.shared.endEditing()
                            } label: {
                                Label("Done", systemImage: "keyboard.chevron.compact.down")
                                    .font(.headline)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 10)
                                    .background(.ultraThinMaterial, in: Capsule())
                            }
                            Spacer()
                        }
                        .padding(.bottom, 6)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .zIndex(1)
                    }
                }
                .animation(.easeInOut, value: notesFocused || amrapFocused)
                .onAppear {
                    let center = UNUserNotificationCenter.current()
                    center.delegate = LocalNotifDelegate.shared
                    requestNotifsIfNeeded()
                    
                    timer.reset()
                    timer.allowStarts = false
                    allowTimerStarts = false
                    
                    liveRepsText = repsText(for: selectedLift)
                    if !activeLifts.contains(selectedLift) {
                        selectedLift = activeLifts.first ?? .bench
                    }
                }
                .onChange(of: settings.workoutsPerWeek) { _, _ in
                    if !activeLifts.contains(selectedLift) {
                        selectedLift = activeLifts.first ?? .bench
                    }
                }
                .onChange(of: settings.fourthLiftRaw) { _, _ in
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
                .onChange(of: settings.tmSquat) { _, _ in weightsVersion += 1 }
                .onChange(of: settings.tmBench) { _, _ in weightsVersion += 1 }
                .onChange(of: settings.tmDeadlift) { _, _ in weightsVersion += 1 }
                .onChange(of: settings.tmRow) { _, _ in weightsVersion += 1 }
                .onChange(of: settings.tmPress) { _, _ in weightsVersion += 1 }
                .onChange(of: settings.roundTo) { _, _ in weightsVersion += 1 }
                .onChange(of: settings.bbbPercent) { _, _ in weightsVersion += 1 }
                // Dismiss settings and dim all but user guide icon
                .onChange(of: tour.currentTarget) { _, newTarget in
                    if newTarget == .helpIcon {
                        withAnimation { showSettings = false }   // dismiss the Settings sheet
                    }
                }
                .onReceive(implements.objectWillChange) { _ in weightsVersion &+= 1 }
                // === collect tour target anchors from inside the NavigationStack ===
                .overlayPreferenceValue(TourTargetsPreferenceKey.self) { value in
                    Color.clear
                        .onAppear { tourTargets = value }
                        .onChange(of: value) { _, newValue in tourTargets = newValue }
                }

                // === TOUR OVERLAY (only when active) ===
                if tour.isActive {
                    GearTourOverlay(targets: tourTargets, proxy: proxy)
                        .environmentObject(tour)
                }
            }
            .onAppear {
                tour.startHighlightingGearIfFirstRun()
            }
        }
        // Optional: make tour available further down if needed later
        .environmentObject(tour)
    }
    
    // MARK: - Main scroll content (split out)
    
    @ViewBuilder
    private var mainContent: some View {
        let m = currentWorkoutMetrics()
        let isWorkoutFinished = workoutState.isWorkoutFinished(lift: selectedLift.rawValue, week: currentWeek)
        
        VStack(spacing: 16) {
            headerView
            
            TrainingMaxesLine(
                tmSquat: settings.tmSquat,
                tmBench: settings.tmBench,
                tmDeadlift: settings.tmDeadlift,
                tmRow: settings.tmRow,
                tmPress: settings.tmPress,
                activeLifts: activeLifts
            )
            
            QuickTargetHeader(
                cycle: currentCycle,
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
                        formula: settings.oneRMFormula,
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
                currentFormula: settings.oneRMFormula,
                availableLifts: activeLifts,
                currentCycle: currentCycle,
                startRest: { secs, fromUser in
                    startRest(secs, fromUser: fromUser)
                }
            )
            .id(weightsVersion)
            
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
            .id(weightsVersion)
            
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
        HStack {
            Button(role: .destructive) {
                showResetConfirm = true
            } label: {
                Label("Reset Workout (Current Lift)", systemImage: "arrow.uturn.backward")
            }
            .buttonStyle(.bordered)
            .tint(.blue)
            .accessibilityLabel("Reset current lift")
            
#if DEBUG
            Button {
                debugAutofillCurrentWorkout()
            } label: {
                Label("Auto-Fill (Debug)", systemImage: "wand.and.stars")
            }
            .buttonStyle(.bordered)
            .tint(.blue)
#endif
        }
    }
    
    // MARK: - Helpers
    
    private func assistanceExerciseFor(_ lift: Lift) -> AssistanceExercise {
        // Read the ID from ProgramSettings (single source of truth)
        let id: String = {
            switch lift {
            case .squat:    return settings.assistSquatID
            case .bench:    return settings.assistBenchID
            case .deadlift: return settings.assistDeadliftID
            case .row:      return settings.assistRowID
            case .press:    return settings.assistPressID
            }
        }()

        // 1) Try user-created first
        if let fromUser = assistanceLibrary.userCreated.first(where: { $0.id == id }) {
            return fromUser
        }
        // 2) Fall back to built-in catalog
        if let fromBuiltIn = AssistanceExercise.byID(id) {
            return fromBuiltIn
        }
        // 3) Lift-aware fallback: choose the first option that matches this lift's picker categories
        let categories = lift.categoriesForPicker  // defined in ExercisePickerView extension
        if let safe = AssistanceLibrary.shared.allExercises.first(where: { categories.contains($0.category) }) {
            return safe
        }
        // Absolute last resort (should never hit): keep the old crash-safe path
        return AssistanceExercise.catalog.first!
    }
    
    private func tmFor(_ lift: Lift) -> Double {
        switch lift {
        case .squat:   return settings.tmSquat
        case .bench:   return settings.tmBench
        case .deadlift:return settings.tmDeadlift
        case .row:     return settings.tmRow
        case .press:   return settings.tmPress
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
                formula: settings.oneRMFormula,
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
        
        // ✅ NEW: Proper error handling
        do {
            try WorkoutStore.shared.append(entry)
        } catch {
            print("⚠️ Failed to save workout: \(error.localizedDescription)")
            savedAlertText += "\n\n⚠️ Warning: Workout may not have been saved."
        }
        
        // --- Update PR stats used in your existing PRs view ---
        if metrics.est > 0 {
            PRStore.shared.considerPR(
                cycle: currentCycle,
                lift: selectedLift.label,
                est1RM: Int(metrics.est.rounded())
            )
        }
        
        
        // ✅ NEW: Generate medal if this is a PR (using your PRService + AwardGenerator)
        if let lt = LiftType(rawValue: selectedLift.label.lowercased()) {
            if let newPR = prService.updateIfEstimatedPR(
                lift: lt,
                estValue: metrics.est,
                date: entry.date
            ) {
                Task { @MainActor in
                    await AwardGenerator.shared.createAndStoreAward(
                        for: newPR,
                        userDisplayName: userDisplayName.isEmpty ? "You" : userDisplayName,
                        store: awardStore
                    )
                    savedAlertText += "\n\n🏆 New PR: \(Int(round(newPR.value))) lb \(lt.rawValue.capitalized)"
                    showSavedAlert = true        // ✅ actually show the alert
                }
            }
        }
        
        // Run auto-advance and decide what to present
        let outcome = maybeAutoAdvanceAfterFinish()

        switch outcome {
        case .none:
            // No week/cycle movement → safe to show the simple Saved alert
            showSavedAlert = true

        case .weekAdvanced:
            // We already showed a toast — skip the Saved alert so the toast isn’t hidden
            break

        case .cycleAdvanced:
            // We already showed a toast + will show the celebration sheet — skip the Saved alert
            break
        }
    }
        
        // ... rest of the method stays the same ...
        
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

    // MARK: - Auto-advance helpers (history-derived)

    // Week is complete when there's a saved entry for every active main lift in that week.
    private func isWeekCompleteInHistory(week: Int) -> Bool {
        let mains = Set(activeLifts.map { $0.label.lowercased() })
        let historyArray: [WorkoutEntry] = WorkoutStore.shared.workouts
        var completed = Set<String>()  // lowercased lift labels

        for entry in historyArray {
            if entry.cycle == currentCycle && entry.programWeek == week {
                completed.insert(entry.lift.lowercased())
            }
        }
        return completed.isSuperset(of: mains)
    }

    // Cycle complete if weeks 1..3 are complete (change to 1..4 if deload is required).
    private func isCycleCompleteInHistory() -> Bool {
        if !isWeekCompleteInHistory(week: 1) { return false }
        if !isWeekCompleteInHistory(week: 2) { return false }
        if !isWeekCompleteInHistory(week: 3) { return false }
        if !isWeekCompleteInHistory(week: 4) { return false }
        return true
    }

    // Decide what to advance after finishing a workout.
    private func maybeAutoAdvanceAfterFinish() -> AdvanceOutcome {
        // 1) Cycle completion takes precedence
        if isCycleCompleteInHistory() {
            let old = currentCycle

            // Apply TM progression and collect change lines for the summary
            let changes = applyTMProgressionForNewCycle(from: old)

            // Move to next cycle
            currentCycle += 1
            currentWeek = 1

            // Fresh week 1 state
            clearAllCompletionFor(week: currentWeek)

            // Reset PR window for new cycle (optional)
            PRStore.shared.resetCycle(currentCycle)

            // Haptic success
            UINotificationFeedbackGenerator().notificationOccurred(.success)

            // Short headline toast
            let styleShort = (settings.progressionStyle == .classic) ? "Classic" : "Auto"
            toast("Cycle \(old) complete → Cycle \(currentCycle) (\(styleShort))")

            // Full celebration sheet
            cycleAdvancedFrom = old
            cycleSummaryLines = changes
            showCycleSummary = true

            return .cycleAdvanced(from: old, to: currentCycle, lines: changes)
        }

        // 2) Otherwise advance week if setting is on and week is complete (allow 1→2→3→4)
        if autoAdvanceWeek && isWeekCompleteInHistory(week: currentWeek) {
            let maxWeek = 4
            if currentWeek < maxWeek {
                let next = currentWeek + 1
                currentWeek = next
                clearAllCompletionFor(week: next)
                toast("Week \(next - 1) complete → Week \(next)")
                return .weekAdvanced(nextWeek: next)
            }
        }

        return .none
    }
    
#if DEBUG
        /// Auto-fills ONLY the current workout (selectedLift @ currentWeek).
        private func debugAutofillCurrentWorkout() {
            let lift = selectedLift
            let liftKey = lift.rawValue
            let week = currentWeek
            let scheme = program.weekScheme(for: week)
            let tmSel = tmFor(lift)
            
            // --- Main sets (1..3) ---
            for setNum in 1...3 {
                workoutState.setSetComplete(lift: liftKey, week: week, set: setNum, value: true)
            }
            
            // --- AMRAP reps if this week has AMRAP ---
            if scheme.main.indices.contains(2), scheme.main[2].amrap {
                let reps = Int.random(in: 5...15)
                workoutState.setAMRAP(lift: liftKey, week: week, reps: reps)
                // keep the on-screen text in sync
                liveRepsText = String(reps)
            } else {
                // deload / no AMRAP
                workoutState.setAMRAP(lift: liftKey, week: week, reps: 0)
                liveRepsText = ""
            }
            
            // --- BBB & Assistance only on non-deload weeks ---
            if scheme.showBBB {
                // BBB sets are tracked as main set indices 4..8; per BBB UI they’re 1..5
                let defaultBBBW = calculator.round(tmSel * bbbPct)
                
                for b in 1...5 {
                    workoutState.setSetComplete(lift: liftKey, week: week, set: b + 3, value: true)
                    workoutState.setBBBWeight(lift: liftKey, week: week, set: b, weight: defaultBBBW)
                    workoutState.setBBBReps(lift: liftKey, week: week, set: b, reps: 10)
                }
                
                // Assistance 1..3 → mark complete; weight/reps fall back to defaults
                for a in 1...3 {
                    workoutState.setAssistComplete(lift: liftKey, week: week, set: a, value: true)
                }
            }
        }
#endif
    
    private struct Toast: View {
        let text: String

        var body: some View {
            let brand = Color(hex: "E55722")  // Your specific orange

            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(brand)
                
                Text(text)
                    .font(.callout.weight(.semibold))
                    .lineLimit(2)
                    .foregroundStyle(brand)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .background(
                Color.black.opacity(0.18),
                in: Capsule()
            )
            .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 1))
            .shadow(color: .black.opacity(0.25), radius: 6, y: 2)
        }
    }

    private func toast(_ s: String) {
        toastText = s
        withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
            showToast = true
        }
    }
    
    private struct CycleSummaryView: View {
        let fromCycle: Int
        let toCycle: Int
        let style: ProgressionStyle
        let lines: [String]  // e.g., ["Squat: 315 → 325 ↑10", "Bench: 225 → 230 ↑5"]

        var body: some View {
            NavigationStack {
                VStack(spacing: 16) {
                    // 🔥 Flame icon in brand orange
                    Image(systemName: "flame.fill")
                        .font(.system(size: 42))
                        .symbolRenderingMode(.monochrome)
                        .foregroundColor(Color(hex: "#e55722"))

                    // 🧱 Headline
                    Text("Cycle \(fromCycle) complete!")
                        .font(.title2.bold())
                        .foregroundColor(Color(hex: "#e55722"))

                    // 🧩 Subheadline
                    Text("Welcome to Cycle \(toCycle) \(styleLabel)")
                        .font(.headline)
                        .foregroundColor(Color(hex: "#2c7f7a")) // teal secondary tone

                    Divider()
                        .overlay(Color(hex: "#e55722").opacity(0.15))
                        .padding(.vertical, 4)

                    // 📈 TM change lines
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(lines, id: \.self) { line in
                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                Image(systemName: "arrow.up.right.circle.fill")
                                    .imageScale(.medium)
                                    .symbolRenderingMode(.monochrome)
                                    .foregroundColor(Color(hex: "#e55722"))

                                // Highlight the delta (last token) in orange
                                let parts = line.split(separator: " ")
                                if let last = parts.last {
                                    let prefix = parts.dropLast().joined(separator: " ")
                                    Text(prefix + " ")
                                        .font(.body.monospaced())
                                    Text(String(last))
                                        .font(.body.monospaced().weight(.semibold))
                                        .foregroundColor(Color(hex: "#e55722"))
                                } else {
                                    Text(line).font(.body.monospaced())
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.black.opacity(0.2))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(Color(hex: "#e55722").opacity(0.1), lineWidth: 1)
                    )

                    Spacer(minLength: 8)

                    // 🪶 Footer
                    Text("Keep momentum. Deload completed and TMs updated — time to build again.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .navigationTitle("Training Max Updates")
                .navigationBarTitleDisplayMode(.inline)
            }
        }

        private var styleLabel: String {
            switch style {
            case .classic: return "(Classic +5/+10)"
            case .auto:    return "(Auto from PRs)"
            }
        }
    }
    
    private enum AdvanceOutcome {
        case none
        case weekAdvanced(nextWeek: Int)
        case cycleAdvanced(from: Int, to: Int, lines: [String])
    }
    
    private func clearAllCompletionFor(week: Int) {
        for lift in activeLifts {
            let key = lift.rawValue

            // Main: sets 1..3 (plus BBB 4..8 when present)
            for mainSet in 1...8 {
                workoutState.setSetComplete(lift: key, week: week, set: mainSet, value: false)
            }

            // BBB weight/reps (1..5) — optional, remove if you prefer to keep last-used weights
            for b in 1...5 {
                workoutState.setBBBWeight(lift: key, week: week, set: b, weight: nil)
                workoutState.setBBBReps(lift: key, week: week, set: b, reps: nil)
            }

            // Assistance: sets 1..3 + weight/reps/useWeight
            for a in 1...3 {
                workoutState.setAssistComplete(lift: key, week: week, set: a, value: false)
                workoutState.setAssistWeight(lift: key, week: week, set: a, weight: nil)
                workoutState.setAssistReps(lift: key, week: week, set: a, reps: nil)
            }
            workoutState.setAssistUseWeight(lift: key, week: week, useWeight: false)

            // AMRAP
            workoutState.setAMRAP(lift: key, week: week, reps: 0)
        }
    }
    }
