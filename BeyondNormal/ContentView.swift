import SwiftUI
import Foundation
import Combine
import UserNotifications

final class LocalNotifDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = LocalNotifDelegate()
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .list])
    }
}

struct WorkoutEntry: Codable, Identifiable {
    let id: UUID
    let date: Date
    let lift: String
    let est1RM: Double
    let totalVolume: Int
    let bbbPct: Double
    let amrapReps: Int
    let notes: String?
    
    init(date: Date, lift: String, est1RM: Double, totalVolume: Int, bbbPct: Double, amrapReps: Int, notes: String? = nil) {
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

final class WorkoutStore {
    static let shared = WorkoutStore()
    private init() {}
    
    private var url: URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent("workout_history.json")
    }
    
    func load() -> [WorkoutEntry] {
        guard let data = try? Data(contentsOf: url) else { return [] }
        return (try? JSONDecoder().decode([WorkoutEntry].self, from: data)) ?? []
    }
    
    func append(_ entry: WorkoutEntry) {
        var all = load()
        all.append(entry)
        if let data = try? JSONEncoder().encode(all) {
            try? data.write(to: url, options: .atomic)
        }
    }
    
    func delete(id: UUID) {
        var all = load()
        all.removeAll { $0.id == id }
        if let data = try? JSONEncoder().encode(all) {
            try? data.write(to: url, options: .atomic)
        }
    }
}

// MARK: - Workout State Manager
final class WorkoutStateManager: ObservableObject {
    @Published private(set) var state: [String: String] = [:]
    @Published private(set) var completedLifts: [String: [String]] = [:]
    
    private let stateKey = "workout_state_v2"
    private let liftsKey = "completed_lifts_by_week"
    private var saveWorkItem: DispatchWorkItem?
    private let queue = DispatchQueue(label: "com.beyondnormal.workout.state", qos: .userInitiated)
    
    init() {
        // Load state asynchronously to avoid blocking app launch
        queue.async { [weak self] in
            self?.loadState()
            self?.loadCompletedLifts()
        }
    }
    
    private func loadState() {
        guard let json = UserDefaults.standard.string(forKey: stateKey),
              let data = json.data(using: .utf8),
              let dict = try? JSONDecoder().decode([String: String].self, from: data) else {
            DispatchQueue.main.async { [weak self] in
                self?.state = [:]
            }
            return
        }
        DispatchQueue.main.async { [weak self] in
            self?.state = dict
        }
    }
    
    private func saveState() {
        // Debounce saves to avoid excessive writes
        saveWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            self.queue.async {
                guard let data = try? JSONEncoder().encode(self.state),
                      let json = String(data: data, encoding: .utf8) else { return }
                UserDefaults.standard.set(json, forKey: self.stateKey)
            }
        }
        saveWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: workItem)
    }
    
    private func loadCompletedLifts() {
        guard let json = UserDefaults.standard.string(forKey: liftsKey),
              let data = json.data(using: .utf8),
              let dict = try? JSONDecoder().decode([String: [String]].self, from: data) else {
            DispatchQueue.main.async { [weak self] in
                self?.completedLifts = [:]
            }
            return
        }
        DispatchQueue.main.async { [weak self] in
            self?.completedLifts = dict
        }
    }
    
    private func saveCompletedLifts() {
        queue.async { [weak self] in
            guard let self = self else { return }
            guard let data = try? JSONEncoder().encode(self.completedLifts),
                  let json = String(data: data, encoding: .utf8) else { return }
            UserDefaults.standard.set(json, forKey: self.liftsKey)
        }
    }
    
    func getSetComplete(lift: String, week: Int, set: Int) -> Bool {
        let key = "\(lift)_w\(week)_set\(set)"
        return state[key] == "true"
    }
    
    func setSetComplete(lift: String, week: Int, set: Int, value: Bool) {
        let key = "\(lift)_w\(week)_set\(set)"
        state[key] = value ? "true" : "false"
        saveState()
    }
    
    func getAssistComplete(lift: String, week: Int, set: Int) -> Bool {
        let key = "\(lift)_w\(week)_assist\(set)"
        return state[key] == "true"
    }
    
    func setAssistComplete(lift: String, week: Int, set: Int, value: Bool) {
        let key = "\(lift)_w\(week)_assist\(set)"
        state[key] = value ? "true" : "false"
        saveState()
    }
    
    func getAMRAP(lift: String, week: Int) -> Int {
        let key = "\(lift)_w\(week)_amrap"
        return Int(state[key] ?? "0") ?? 0
    }
    
    func setAMRAP(lift: String, week: Int, reps: Int) {
        let key = "\(lift)_w\(week)_amrap"
        state[key] = String(reps)
        saveState()
    }
    
    func markLiftComplete(_ lift: String, week: Int) {
        var lifts = completedLifts["w\(week)"] ?? []
        if !lifts.contains(lift) {
            lifts.append(lift)
            completedLifts["w\(week)"] = lifts
            saveCompletedLifts()
        }
    }
    
    func allLiftsComplete(for week: Int, totalLifts: Int) -> Bool {
        let lifts = completedLifts["w\(week)"] ?? []
        return lifts.count >= totalLifts
    }
    
    func resetCompletedLifts(for week: Int) {
        completedLifts["w\(week)"] = []
        saveCompletedLifts()
    }
    
    func resetLift(lift: String, week: Int) {
        for setNum in 1...8 {
            let key = "\(lift)_w\(week)_set\(setNum)"
            state.removeValue(forKey: key)
        }
        for setNum in 1...3 {
            let key = "\(lift)_w\(week)_assist\(setNum)"
            state.removeValue(forKey: key)
        }
        let amrapKey = "\(lift)_w\(week)_amrap"
        state.removeValue(forKey: amrapKey)
        saveState()
        
        // IMPORTANT: Also remove from completed lifts tracking
        var lifts = completedLifts["w\(week)"] ?? []
        lifts.removeAll { $0 == lift }
        completedLifts["w\(week)"] = lifts
        saveCompletedLifts()
    }
}

// MARK: - Timer Manager (Isolated from view)
final class TimerManager: ObservableObject {
    @Published var remaining: Int = 0
    @Published var isRunning: Bool = false
    
    private var endTime: Date?
    private var cancellable: AnyCancellable?
    
    func start(seconds: Int) {
        endTime = Date().addingTimeInterval(TimeInterval(seconds))
        remaining = seconds
        isRunning = true
        scheduleNotification(in: seconds)
        startTicking()
    }
    
    func pause() {
        isRunning = false
        endTime = nil
        cancellable?.cancel()
        cancelNotification()
    }
    
    func reset() {
        isRunning = false
        endTime = nil
        remaining = 0
        cancellable?.cancel()
        cancelNotification()
    }
    
    private func startTicking() {
        cancellable?.cancel()
        cancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }
    
    private func tick() {
        guard isRunning, let end = endTime else { return }
        let left = max(0, Int(end.timeIntervalSinceNow.rounded()))
        remaining = left
        if left == 0 {
            isRunning = false
            endTime = nil
            cancellable?.cancel()
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
    
    private func scheduleNotification(in seconds: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Rest finished"
        content.body = "Time to lift!"
        content.sound = UNNotificationSound.default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(seconds), repeats: false)
        let req = UNNotificationRequest(identifier: "rest-timer", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(req)
    }
    
    private func cancelNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["rest-timer"])
    }
}

// MARK: - Plate Calculator (Cached)
final class PlateCalculator {
    private let barWeight: Double
    private let roundTo: Double
    private let inventory: [Double]
    private var cache: [String: [Double]] = [:]
    
    init(barWeight: Double, roundTo: Double, inventory: [Double]) {
        self.barWeight = barWeight
        self.roundTo = roundTo
        self.inventory = inventory.filter { $0.isFinite && $0 > 0 }.sorted(by: >)
    }
    
    func round(_ x: Double) -> Double {
        let inc = (roundTo.isFinite && roundTo > 0) ? roundTo : 0.5
        return (x / inc).rounded() * inc
    }
    
    func plates(target: Double, barWeight: Double? = nil) -> [Double] {
        let bar = barWeight ?? self.barWeight
        let key = "\(target)_\(bar)"
        
        if let cached = cache[key] {
            return cached
        }
        
        guard target.isFinite, bar.isFinite, bar > 0, target >= bar else { return [] }
        var remainingPerSide = (target - bar) / 2.0
        guard remainingPerSide.isFinite, remainingPerSide >= 0 else { return [] }
        
        var out: [Double] = []
        for p in inventory {
            var guardCounter = 0
            while remainingPerSide + 1e-9 >= p && guardCounter < 200 {
                out.append(p)
                remainingPerSide -= p
                guardCounter += 1
            }
        }
        
        cache[key] = out
        return out
    }
}

struct ContentView: View {
    @AppStorage("tm_squat")    private var tmSquat: Double = 315
    @AppStorage("tm_bench")    private var tmBench: Double = 225
    @AppStorage("tm_deadlift") private var tmDeadlift: Double = 405
    @AppStorage("tm_row")      private var tmRow: Double = 185
    
    @AppStorage("bar_weight")  private var barWeight: Double = 45
    @AppStorage("round_to")    private var roundTo: Double = 5
    @AppStorage("bbb_pct")     private var bbbPct: Double = 0.50
    
    @AppStorage("assist_weight_squat")    private var assistWeightSquat: Double = 0
    @AppStorage("assist_weight_bench")    private var assistWeightBench: Double = 65
    @AppStorage("assist_weight_deadlift") private var assistWeightDeadlift: Double = 0
    @AppStorage("assist_weight_row")      private var assistWeightRow: Double = 0
    
    @AppStorage("timer_regular_sec") private var timerRegularSec: Int = 240
    @AppStorage("timer_bbb_sec")     private var timerBBBsec: Int = 180
    @AppStorage("current_week")      private var currentWeek: Int = 1
    
    @AppStorage("tm_progression_style") private var tmProgStyleRaw: String = "classic"
    @AppStorage("auto_advance_week")    private var autoAdvanceWeek: Bool = false
    
    @StateObject private var workoutState = WorkoutStateManager()
    @StateObject private var timer = TimerManager()
    
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
    
    private var calculator: PlateCalculator {
        PlateCalculator(barWeight: barWeight, roundTo: roundTo, inventory: [45, 35, 25, 10, 5, 2.5])
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
                        
                        Text("v0.0.8 • Final Optimization")
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
                autoAdvanceWeek: $autoAdvanceWeek
            )
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showHistory) {
            HistorySheet()
                .presentationDetents([.medium, .large])
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
        let scheme = weekScheme(currentWeek)
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
        let scheme = weekScheme(currentWeek)
        
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
                let bbbWeight = calculator.round(tm * bbbPct)
                
                Text(selectedLift == .row
                     ? "Assistance — Lat Pulldown 5×10 @ \(Int(bbbPct * 100))% TM (Row)"
                     : "Assistance — BBB 5×10 @ \(Int(bbbPct * 100))% TM")
                .font(.headline)
                
                ForEach(4...8, id: \.self) { setNum in
                    SetRow(
                        label: "BBB Set \(setNum - 3) ×10",
                        weight: bbbWeight,
                        perSide: (selectedLift == .row) ? [] : calculator.plates(target: bbbWeight),
                        done: setBinding(setNum),
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
        let scheme = weekScheme(currentWeek)
        let a = assistanceFor(selectedLift)
        
        return Group {
            if scheme.showBBB {
                Divider().padding(.vertical, 6)
                
                Text("Assistance — \(a.title)")
                    .font(.headline)
                
                if a.defaultBarWeight > 0 {
                    HStack {
                        Text("Assistance Weight (total):")
                        Spacer()
                        TextField("\(Int(max(a.defaultBarWeight, 0)))",
                                  value: assistWeightBinding(for: selectedLift),
                                  format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        Text("lb")
                    }
                }
                
                ForEach(1...3, id: \.self) { i in
                    let totalAssistWeight = calculator.round(max(
                        assistWeightBinding(for: selectedLift).wrappedValue,
                        a.defaultBarWeight
                    ))
                    let perSidePlates: [Double] =
                    a.defaultBarWeight > 0
                    ? (a.useEZBar ? calculator.plates(target: totalAssistWeight, barWeight: 25)
                       : calculator.plates(target: totalAssistWeight))
                    : []
                    SetRow(
                        label: "Set \(i) ×\(a.defaultReps)",
                        weight: totalAssistWeight,
                        perSide: perSidePlates,
                        done: assistSetBinding(i),
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
    
    // MARK: - Types
    
    private enum Lift: String, CaseIterable, Identifiable {
        case squat = "SQ", bench = "BP", deadlift = "DL", row = "RW"
        var id: String { rawValue }
        var label: String {
            switch self {
            case .squat: return "Squat"
            case .bench: return "Bench"
            case .deadlift: return "Deadlift"
            case .row: return "Row"
            }
        }
    }
    
    private struct AssistanceDef {
        let title: String
        let defaultBarWeight: Double
        let defaultSets: Int
        let defaultReps: Int
        let useEZBar: Bool
    }
    
    private struct SetScheme { let pct: Double; let reps: Int; let amrap: Bool }
    
    private struct WeekSchemeResult {
        let main: [SetScheme]
        let showBBB: Bool
        let topLine: String
    }
    
    // MARK: - Helpers
    
    private func assistanceFor(_ lift: Lift) -> AssistanceDef {
        switch lift {
        case .squat:    return .init(title: "Hanging Leg Raise", defaultBarWeight: 0,  defaultSets: 3, defaultReps: 12, useEZBar: false)
        case .bench:    return .init(title: "Lying Triceps Extension (EZ bar 25 lb)", defaultBarWeight: 25, defaultSets: 3, defaultReps: 12, useEZBar: true)
        case .deadlift: return .init(title: "Back Extension", defaultBarWeight: 0,  defaultSets: 3, defaultReps: 12, useEZBar: false)
        case .row:      return .init(title: "Spider Curls (DBs)", defaultBarWeight: 0,  defaultSets: 3, defaultReps: 12, useEZBar: false)
        }
    }
    
    private func tmFor(_ lift: Lift) -> Double {
        switch lift {
        case .squat: return tmSquat
        case .bench: return tmBench
        case .deadlift: return tmDeadlift
        case .row: return tmRow
        }
    }
    
    private func weekScheme(_ week: Int) -> WeekSchemeResult {
        switch week {
        case 2:
            return .init(
                main: [.init(pct:0.70, reps:3, amrap:false),
                       .init(pct:0.80, reps:3, amrap:false),
                       .init(pct:0.90, reps:3, amrap:true)],
                showBBB: true,
                topLine: "90% × 3+"
            )
        case 3:
            return .init(
                main: [.init(pct:0.75, reps:5, amrap:false),
                       .init(pct:0.85, reps:3, amrap:false),
                       .init(pct:0.95, reps:1, amrap:true)],
                showBBB: true,
                topLine: "95% × 1+"
            )
        case 4:
            return .init(
                main: [.init(pct:0.40, reps:5, amrap:false),
                       .init(pct:0.50, reps:5, amrap:false),
                       .init(pct:0.60, reps:5, amrap:false)],
                showBBB: false,
                topLine: "Deload: 60% × 5"
            )
        default:
            return .init(
                main: [.init(pct:0.65, reps:5, amrap:false),
                       .init(pct:0.75, reps:5, amrap:false),
                       .init(pct:0.85, reps:5, amrap:true)],
                showBBB: true,
                topLine: "85% × 5+"
            )
        }
    }
    
    private func setBinding(_ num: Int) -> Binding<Bool> {
        return Binding(
            get: { self.workoutState.getSetComplete(lift: self.selectedLift.rawValue, week: self.currentWeek, set: num) },
            set: { newValue in
                self.workoutState.setSetComplete(lift: self.selectedLift.rawValue, week: self.currentWeek, set: num, value: newValue)
            }
        )
    }
    
    private func assistSetBinding(_ n: Int) -> Binding<Bool> {
        return Binding(
            get: { self.workoutState.getAssistComplete(lift: self.selectedLift.rawValue, week: self.currentWeek, set: n) },
            set: { newValue in
                self.workoutState.setAssistComplete(lift: self.selectedLift.rawValue, week: self.currentWeek, set: n, value: newValue)
            }
        )
    }
    
    private func assistWeightBinding(for lift: Lift) -> Binding<Double> {
        switch lift {
        case .squat:    return $assistWeightSquat
        case .bench:    return $assistWeightBench
        case .deadlift: return $assistWeightDeadlift
        case .row:      return $assistWeightRow
        }
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
        let scheme = weekScheme(currentWeek)
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
        let bbbW = calculator.round(tmSel * bbbPct)
        let bbbPerSet = scheme.showBBB ? bbbW * 10 : 0
        var bbbVol = 0.0
        for setNum in 4...8 {
            if workoutState.getSetComplete(lift: selectedLift.rawValue, week: currentWeek, set: setNum) {
                bbbVol += bbbPerSet
            }
        }
        
        // Assistance volume
        let assistDef = assistanceFor(selectedLift)
        let assistW = max(assistWeightBinding(for: selectedLift).wrappedValue, assistDef.defaultBarWeight)
        var assistVol = 0.0
        for setNum in 1...3 {
            if scheme.showBBB && workoutState.getAssistComplete(lift: selectedLift.rawValue, week: currentWeek, set: setNum) {
                assistVol += assistW * Double(assistDef.defaultReps)
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
    
    // MARK: - Row Components
    
    private struct SetRow: View {
        let label: String
        let weight: Double
        let perSide: [Double]
        @Binding var done: Bool
        var onCheck: ((Bool) -> Void)? = nil
        
        var body: some View {
            HStack(alignment: .firstTextBaseline) {
                Toggle(isOn: $done) { Text(label) }
                Spacer(minLength: 12)
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Int(weight)) lb").font(.headline)
                    if !perSide.isEmpty {
                        Text("Per side: " + plateList(perSide))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .onChange(of: done) { _, new in
                onCheck?(new)
            }
        }
        
        private func plateList(_ ps: [Double]) -> String {
            ps.map { $0.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int($0))" : String(format: "%.1f", $0) }
                .joined(separator: ", ")
        }
    }
    
    private struct AMRAPRow: View {
        let label: String
        let weight: Double
        let perSide: [Double]
        @Binding var done: Bool
        @Binding var reps: String
        let est1RM: Double
        var onCheck: ((Bool) -> Void)? = nil
        var focus: FocusState<Bool>.Binding

        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    Toggle(isOn: $done) { Text(label).font(.headline) }
                    Spacer(minLength: 12)
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(Int(weight)) lb").font(.headline)
                        if !perSide.isEmpty {
                            Text("Per side: " + plateList(perSide))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .onChange(of: done) { _, new in onCheck?(new) }

                HStack {
                    Text("AMRAP reps:")
                    TextField("e.g. 8", text: $reps)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                        .focused(focus)
                        .submitLabel(.done)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .onSubmit {
                            focus.wrappedValue = false
                        }
                        .onChange(of: reps) { _, s in
                            // Only allow digits, prevent RTI issues
                            DispatchQueue.main.async {
                                let digits = s.filter(\.isNumber)
                                if digits != s { reps = digits }
                            }
                        }

                    if est1RM > 0 {
                        Spacer()
                        Text("Est 1RM ≈ \(Int(est1RM)) lb")
                            .font(.subheadline)
                            .foregroundStyle(.blue)
                    }
                }
            }
        }

        private func plateList(_ ps: [Double]) -> String {
            ps.map { $0.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int($0))" : String(format: "%.1f", $0) }
              .joined(separator: ", ")
        }
    }
}

// MARK: - History Sheet

private struct HistorySheet: View {
    @State private var entries: [WorkoutEntry] = []
    @State private var expanded: Set<UUID> = []
    
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
            }
            .onAppear {
                entries = WorkoutStore.shared.load().sorted { $0.date > $1.date }
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
                    numField("Bar Weight (lb)", value: $tmpBarWeight, field: .barWeight)
                    numField("Round To (lb)", value: $tmpRoundTo, field: .roundTo)
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
                
                Section("Behavior") {
                    Toggle("Auto-advance week after finishing workout", isOn: $autoAdvanceWeek)
                }
                
                Section {
                    Button(role: .destructive) {
                        tmpSquat = "315"; tmpBench = "225"
                        tmpDeadlift = "405"; tmpRow = "185"
                        tmpBarWeight = "45"; tmpRoundTo = "5"
                    } label: {
                        Label("Reset to defaults", systemImage: "arrow.counterclockwise")
                    }
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
