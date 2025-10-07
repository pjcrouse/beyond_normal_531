import SwiftUI
import Foundation
import Combine
import UserNotifications

final class LocalNotifDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = LocalNotifDelegate()
    
    // Show banner + play sound while app is in foreground
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
    
    private func save(_ all: [WorkoutEntry]) {
        if let data = try? JSONEncoder().encode(all) {
            try? data.write(to: url, options: .atomic)
        }
    }
    
    func delete(id: UUID) {
        var all = load()
        all.removeAll { $0.id == id }
        save(all)
    }
}

struct ContentView: View {
    // Persisted Training Maxes (lb)
    @AppStorage("tm_squat")    private var tmSquat: Double    = 315
    @AppStorage("tm_bench")    private var tmBench: Double    = 225
    @AppStorage("tm_deadlift") private var tmDeadlift: Double = 405
    @AppStorage("tm_row") private var tmRow: Double = 185
    
    // Persisted loading prefs
    @AppStorage("bar_weight")  private var barWeight: Double  = 45
    @AppStorage("round_to")    private var roundTo: Double    = 5
    
    // Persisted AMRAP reps per lift
    @AppStorage("amrap_reps_squat")    private var amrapRepsSquat: Int = 0
    @AppStorage("amrap_reps_bench")    private var amrapRepsBench: Int = 0
    @AppStorage("amrap_reps_deadlift") private var amrapRepsDeadlift: Int = 0
    @AppStorage("amrap_reps_row") private var amrapRepsRow: Int = 0
    
    // BBB percent (50–70% of TM)
    @AppStorage("bbb_pct") private var bbbPct: Double = 0.50
    
    // Persisted per-lift set completion - Squat
    @AppStorage("set1_done_squat") private var set1DoneSquat = false
    @AppStorage("set2_done_squat") private var set2DoneSquat = false
    @AppStorage("set3_done_squat") private var set3DoneSquat = false
    @AppStorage("bbb1_done_squat") private var bbb1DoneSquat = false
    @AppStorage("bbb2_done_squat") private var bbb2DoneSquat = false
    @AppStorage("bbb3_done_squat") private var bbb3DoneSquat = false
    @AppStorage("bbb4_done_squat") private var bbb4DoneSquat = false
    @AppStorage("bbb5_done_squat") private var bbb5DoneSquat = false
    
    // Persisted per-lift set completion – Bench
    @AppStorage("set1_done_bench") private var set1DoneBench = false
    @AppStorage("set2_done_bench") private var set2DoneBench = false
    @AppStorage("set3_done_bench") private var set3DoneBench = false
    @AppStorage("bbb1_done_bench") private var bbb1DoneBench = false
    @AppStorage("bbb2_done_bench") private var bbb2DoneBench = false
    @AppStorage("bbb3_done_bench") private var bbb3DoneBench = false
    @AppStorage("bbb4_done_bench") private var bbb4DoneBench = false
    @AppStorage("bbb5_done_bench") private var bbb5DoneBench = false
    
    // Persisted per-lift set completion – Deadlift
    @AppStorage("set1_done_deadlift") private var set1DoneDeadlift = false
    @AppStorage("set2_done_deadlift") private var set2DoneDeadlift = false
    @AppStorage("set3_done_deadlift") private var set3DoneDeadlift = false
    @AppStorage("bbb1_done_deadlift") private var bbb1DoneDeadlift = false
    @AppStorage("bbb2_done_deadlift") private var bbb2DoneDeadlift = false
    @AppStorage("bbb3_done_deadlift") private var bbb3DoneDeadlift = false
    @AppStorage("bbb4_done_deadlift") private var bbb4DoneDeadlift = false
    @AppStorage("bbb5_done_deadlift") private var bbb5DoneDeadlift = false
    
    
    // Persisted per-lift set completion – Row
    @AppStorage("set1_done_row") private var set1DoneRow = false
    @AppStorage("set2_done_row") private var set2DoneRow = false
    @AppStorage("set3_done_row") private var set3DoneRow = false
    @AppStorage("bbb1_done_row") private var bbb1DoneRow = false
    @AppStorage("bbb2_done_row") private var bbb2DoneRow = false
    @AppStorage("bbb3_done_row") private var bbb3DoneRow = false
    @AppStorage("bbb4_done_row") private var bbb4DoneRow = false
    @AppStorage("bbb5_done_row") private var bbb5DoneRow = false
    
    
    // Assistance weights (use total or 0 if bodyweight/DB)
    @AppStorage("assist_weight_squat")    private var assistWeightSquat: Double = 0
    @AppStorage("assist_weight_bench")    private var assistWeightBench: Double = 65
    @AppStorage("assist_weight_deadlift") private var assistWeightDeadlift: Double = 0
    @AppStorage("assist_weight_row") private var assistWeightRow: Double = 0
    
    // Three set checkboxes per lift (expand to 4–5 later if needed)
    @AppStorage("assist1_done_squat") private var assist1DoneSquat = false
    @AppStorage("assist2_done_squat") private var assist2DoneSquat = false
    @AppStorage("assist3_done_squat") private var assist3DoneSquat = false
    @AppStorage("assist1_done_bench") private var assist1DoneBench = false
    @AppStorage("assist2_done_bench") private var assist2DoneBench = false
    @AppStorage("assist3_done_bench") private var assist3DoneBench = false
    @AppStorage("assist1_done_deadlift") private var assist1DoneDeadlift = false
    @AppStorage("assist2_done_deadlift") private var assist2DoneDeadlift = false
    @AppStorage("assist3_done_deadlift") private var assist3DoneDeadlift = false
    @AppStorage("assist1_done_row") private var assist1DoneRow = false
    @AppStorage("assist2_done_row") private var assist2DoneRow = false
    @AppStorage("assist3_done_row") private var assist3DoneRow = false
    
    // Timer related settings
    @AppStorage("timer_regular_sec") private var timerRegularSec: Int = 240   // 4:00
    @AppStorage("timer_bbb_sec")     private var timerBBBsec: Int = 180       // 3:00
    
    @AppStorage("current_week") private var currentWeek: Int = 1 // 1..4
    
    @AppStorage("tm_progression_style") private var tmProgStyleRaw: String = "classic" // "classic" or "auto"
    
    // Notes related
    @State private var workoutNotes: String = ""
    
    // Plate set for tonight (we’ll make this editable later)
    private let plateInventory: [Double] = [45, 35, 25, 10, 5, 2.5]
    
    // UI state
    @State private var showSettings = false
    @State private var showPRs = false
    @State private var selectedLift: Lift = .bench
    @State private var liveRepsText: String = ""   // text field binding for current lift
    @State private var showResetConfirm = false
    @State private var showSavedAlert = false
    @State private var showHistory = false
    @State private var timerEnd: Date? = nil
    @State private var timerRemaining: Int = 0
    @State private var timerRunning: Bool = false
    
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
                        // Logo / Title
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
                        
                        // Saved TM readout
                        VStack(spacing: 6) {
                            Text("Training Maxes (lb)").font(.headline)
                            Text("SQ \(int(tmSquat))  •  BP \(int(tmBench))  •  DL \(int(tmDeadlift))  •  ROW \(int(tmRow))")
                                .foregroundStyle(.secondary)
                        }
                        
                        // Dynamic quick target for the selected lift
                        VStack(spacing: 4) {
                            let tmSel = tmFor(selectedLift)
                            let scheme = weekScheme(currentWeek)
                            let topPct = scheme.main.last?.pct ?? 0.85
                            let topW = roundToInc(tmSel * topPct)
                            
                            Text("Week \(currentWeek) • \(selectedLift.label)")
                                .font(.headline)
                            
                            Text("\(scheme.topLine) → \(int(topW)) lb")
                                .font(.title3.weight(.bold))
                                .foregroundStyle(.blue)
                        }
                        .padding(.top, 6)
                        
                        // Expandable PRs
                        DisclosureGroup(isExpanded: $showPRs) {
                            let tmSel = tmFor(selectedLift)
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Week 1: 85% × 5+ → \(int(roundToInc(tmSel * 0.85))) lb")
                                Text("Week 2: 90% × 3+ → \(int(roundToInc(tmSel * 0.90))) lb")
                                Text("Week 3: 95% × 1+ → \(int(roundToInc(tmSel * 0.95))) lb")
                            }
                            .padding(.top, 4)
                        } label: {
                            Text("PR sets • \(selectedLift.label)")
                                .font(.headline)
                        }
                        
                        // ===== Week X workout block =====
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Week \(currentWeek) Workout")
                                    .font(.title3.weight(.bold))
                                Spacer()
                                // Week picker
                                Picker("Week", selection: $currentWeek) {
                                    Text("1").tag(1); Text("2").tag(2); Text("3").tag(3); Text("4").tag(4);
                                }
                                .pickerStyle(.segmented)
                                .frame(maxWidth: 220)
                            }
                            // Lift picker
                            Picker("Lift", selection: $selectedLift) {
                                ForEach(Lift.allCases) { Text($0.label).tag($0) }
                            }
                            .pickerStyle(.segmented)
                            .onChange(of: selectedLift) { _, new in
                                liveRepsText = repsText(for: new)
                            }
                            
                            let tm = tmFor(selectedLift)
                            let scheme = weekScheme(currentWeek)
                            let s0 = scheme.main[0], s1 = scheme.main[1], s2 = scheme.main[2]
                            let w0 = roundToInc(tm * s0.pct)
                            let w1 = roundToInc(tm * s1.pct)
                            let w2 = roundToInc(tm * s2.pct)
                            
                            // --- MAIN SET 1 ---
                            SetRow(
                                label: "\(Int(s0.pct * 100))% × \(s0.reps)",
                                weight: w0,
                                perSide: platesFor(target: w0),
                                done: setBinding(1),
                                onCheck: { checked in if checked { startTimer(seconds: timerRegularSec) } }
                            )
                            
                            // --- MAIN SET 2 ---
                            SetRow(
                                label: "\(Int(s1.pct * 100))% × \(s1.reps)",
                                weight: w1,
                                perSide: platesFor(target: w1),
                                done: setBinding(2),
                                onCheck: { checked in if checked { startTimer(seconds: timerRegularSec) } }
                            )
                            
                            // --- MAIN SET 3 (AMRAP on W1–3, fixed on deload W4) ---
                            if s2.amrap {
                                AMRAPRow(
                                    label: "\(Int(s2.pct * 100))% × \(s2.reps)+",
                                    weight: w2,
                                    perSide: platesFor(target: w2),
                                    done: setBinding(3),
                                    reps: $liveRepsText,
                                    est1RM: est1RM(for: selectedLift, weight: roundToInc(tm * scheme.main[2].pct)),
                                    onCheck: { checked in if checked { startTimer(seconds: timerRegularSec) } }
                                )
                            } else {
                                SetRow(
                                    label: "\(Int(s2.pct * 100))% × \(s2.reps)",
                                    weight: w2,
                                    perSide: platesFor(target: w2),
                                    done: setBinding(3),
                                    onCheck: { checked in if checked { startTimer(seconds: timerRegularSec) } }
                                )
                                // Nice nudge on deload
                                Text("Deload week: skip BBB/assistance and add 10–20 min easy cardio.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            // ===== Workout Notes (one per workout) =====
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Workout Notes").font(.headline)
                                    Spacer()
                                    Text("saved with history").font(.caption).foregroundStyle(.secondary)
                                }
                                
                                TextEditor(text: $workoutNotes)
                                    .frame(minHeight: 80)
                                    .scrollContentBackground(.hidden)
                                    .padding(8)
                                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                            }
                            
                            // ===== Rest Timer =====
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Rest Timer").font(.headline)
                                    Spacer()
                                    Text(timerRunning ? "Running" : "Ready")
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                                
                                Text(timerRemaining > 0 ? mmss(timerRemaining) :
                                        "Ready (\(mmss(timerRegularSec)) / \(mmss(timerBBBsec)))")
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                                
                                HStack(spacing: 12) {
                                    Button {
                                        startTimer(seconds: timerRegularSec)
                                    } label: { Label("Start Regular", systemImage: "timer") }
                                    
                                    Button {
                                        startTimer(seconds: timerBBBsec)
                                    } label: { Label("Start BBB", systemImage: "timer") }
                                }
                                .buttonStyle(.bordered)
                                
                                HStack(spacing: 12) {
                                    Button(timerRunning ? "Pause" : "Resume") {
                                        if timerRunning { pauseTimer() }
                                        else { startTimer(seconds: max(timerRemaining, 1)) }
                                    }
                                    .buttonStyle(.bordered)
                                    
                                    Button("Reset", role: .destructive) { resetTimer() }
                                        .buttonStyle(.bordered)
                                }
                            }
                            .padding()
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                            
                            // --- BBB / Lat Pulldown (on Row day) ---
                            Divider().padding(.vertical, 4)
                            let bbbWeight = roundToInc(tm * bbbPct)
                            
                            if scheme.showBBB {
                                // Label switches on Row day
                                Text(selectedLift == .row
                                     ? "Assistance — Lat Pulldown 5×10 @ \(Int(bbbPct * 100))% TM (Row)"
                                     : "Assistance — BBB 5×10 @ \(Int(bbbPct * 100))% TM")
                                .font(.headline)
                                
                                // Reuse SetRow; hide per-side plates on Row day (pulldown)
                                SetRow(
                                    label: "BBB Set 1 ×10",
                                    weight: bbbWeight,
                                    perSide: (selectedLift == .row) ? [] : platesFor(target: bbbWeight),
                                    done: setBinding(4),
                                    onCheck: { checked in if checked { startTimer(seconds: timerBBBsec) } }
                                )
                                
                                SetRow(
                                    label: "BBB Set 2 ×10",
                                    weight: bbbWeight,
                                    perSide: (selectedLift == .row) ? [] : platesFor(target: bbbWeight),
                                    done: setBinding(5),
                                    onCheck: { checked in if checked { startTimer(seconds: timerBBBsec) } }
                                )
                                
                                SetRow(
                                    label: "BBB Set 3 ×10",
                                    weight: bbbWeight,
                                    perSide: (selectedLift == .row) ? [] : platesFor(target: bbbWeight),
                                    done: setBinding(6),
                                    onCheck: { checked in if checked { startTimer(seconds: timerBBBsec) } }
                                )
                                
                                SetRow(
                                    label: "BBB Set 4 ×10",
                                    weight: bbbWeight,
                                    perSide: (selectedLift == .row) ? [] : platesFor(target: bbbWeight),
                                    done: setBinding(7),
                                    onCheck: { checked in if checked { startTimer(seconds: timerBBBsec) } }
                                )
                                
                                SetRow(
                                    label: "BBB Set 5 ×10",
                                    weight: bbbWeight,
                                    perSide: (selectedLift == .row) ? [] : platesFor(target: bbbWeight),
                                    done: setBinding(8),
                                    onCheck: { checked in if checked { startTimer(seconds: timerBBBsec) } }
                                )
                            } else{
                                Text("Deload week: skip BBB/assistance and add ~30 min easy cardio.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .onChange(of: liveRepsText) { _, new in
                            saveReps(new, for: selectedLift)
                        }
                        .onAppear {
                            liveRepsText = repsText(for: selectedLift)
                        }
                    }
                    .padding()
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                    
                    // --- Assistance ---
                    
                    Divider().padding(.vertical, 6)
                    
                    let a = assistanceFor(selectedLift)
                    if weekScheme(currentWeek).showBBB {
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
                                Text("lb")
                            }
                        }
                        
                        ForEach(1...3, id: \.self) { i in
                            let totalAssistWeight = roundToInc(max(
                                assistWeightBinding(for: selectedLift).wrappedValue,
                                a.defaultBarWeight
                            ))
                            let perSidePlates: [Double] =
                            a.defaultBarWeight > 0
                            ? (a.useEZBar ? platesForEZ(target: totalAssistWeight)
                               : platesFor(target: totalAssistWeight))
                            : []
                            SetRow(
                                label: "Set \(i) ×\(a.defaultReps)",
                                weight: totalAssistWeight,
                                perSide: perSidePlates,
                                done: assistSetBinding(i),
                                onCheck: { checked in
                                    if checked { startTimer(seconds: timerBBBsec) }
                                }
                            )
                        }
                    }
                    
                    // ===== Workout Summary =====
                    Divider().padding(.vertical, 8)
                    
                    let metrics = currentWorkoutMetrics()
                    
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
                    
                    // ===== Finish Workout =====
                    Button {
                        let metrics = currentWorkoutMetrics()
                        let entry = WorkoutEntry(
                            date: .now,
                            lift: selectedLift.label,
                            est1RM: metrics.est,
                            totalVolume: metrics.totalVol,
                            bbbPct: bbbPct,
                            amrapReps: currentAMRAP,
                            notes: workoutNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : workoutNotes
                        )
                        WorkoutStore.shared.append(entry)
                        showSavedAlert = true
                    } label: {
                        Label("Finish Workout", systemImage: "checkmark.seal.fill")
                            .font(.headline)
                    }
                    .buttonStyle(.borderedProminent)
                    
                    // ===== Reset Workout =====
                    
                    Divider().padding(.vertical, 6)
                    
                    Button(role: .destructive) {
                        showResetConfirm = true
                    } label: {
                        Label("Reset Workout (Current Lift)", systemImage: "arrow.uturn.backward")
                    }
                    
                    Text("v0.0.4 • Dev Build")
                        .font(.footnote)
                        .foregroundStyle(.tertiary)
                }
                .padding(.vertical)
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
                tmProgStyleRaw: $tmProgStyleRaw
            )
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showHistory) {
            HistorySheet()
                .presentationDetents([.medium, .large])
        }
        .alert("Reset current lift?", isPresented: $showResetConfirm) {
            Button("Reset", role: .destructive) { resetCurrentLift() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will clear 65/75/85 sets, BBB sets, assistance sets, AMRAP reps, and workout notes.")
        }
        .alert("Saved!", isPresented: $showSavedAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Logged \(selectedLift.label) • Est 1RM \(Int(currentWorkoutMetrics().est)) • Volume \(currentWorkoutMetrics().totalVol) lb")
        }
        .onReceive(tick) { _ in
            guard timerRunning, let end = timerEnd else { return }
            let left = max(0, Int(end.timeIntervalSinceNow.rounded()))
            timerRemaining = left
            if left == 0 {
                timerRunning = false
                timerEnd = nil
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        }
        .onAppear {
            let center = UNUserNotificationCenter.current()
            center.delegate = LocalNotifDelegate.shared
            requestNotifsIfNeeded() // you already have this helper
        }
    }
    
    // MARK: - Types & helpers
    
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
    
    private func assistanceFor(_ lift: Lift) -> AssistanceDef {
        switch lift {
        case .squat:    return .init(title: "Hanging Leg Raise", defaultBarWeight: 0,  defaultSets: 3, defaultReps: 12, useEZBar: false)
        case .bench:    return .init(title: "Lying Triceps Extension (EZ bar 25 lb)", defaultBarWeight: 25, defaultSets: 3, defaultReps: 12, useEZBar: true)
        case .deadlift: return .init(title: "Back Extension", defaultBarWeight: 0,  defaultSets: 3, defaultReps: 12, useEZBar: false)
        case .row:    return .init(title: "Spider Curls (DBs)", defaultBarWeight: 0,  defaultSets: 3, defaultReps: 12, useEZBar: false)
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
    
    private enum TMProgressionStyle: String, CaseIterable {
        case classic, auto
        var label: String {
            switch self {
            case .classic: return "Classic (+5/+10)"
            case .auto:    return "Auto (90% of 1RM)"
            }
        }
    }
    private var tmProgStyle: TMProgressionStyle {
        TMProgressionStyle(rawValue: tmProgStyleRaw) ?? .classic
    }
    
    private struct SetScheme { let pct: Double; let reps: Int; let amrap: Bool }
    
    private func weekScheme(_ week: Int) -> (main: [SetScheme], showBBB: Bool, topLine: String) {
        switch week {
        case 2:
            // 70×3, 80×3, 90×3+
            return ([.init(pct:0.70, reps:3, amrap:false),
                     .init(pct:0.80, reps:3, amrap:false),
                     .init(pct:0.90, reps:3, amrap:true)],
                    true,
                    "90% × 3+")
        case 3:
            // 75×5, 85×3, 95×1+
            return ([.init(pct:0.75, reps:5, amrap:false),
                     .init(pct:0.85, reps:3, amrap:false),
                     .init(pct:0.95, reps:1, amrap:true)],
                    true,
                    "95% × 1+")
        case 4:
            // Deload 40/50/60 ×5 (no AMRAP, no BBB, no Assistance)
            return ([.init(pct:0.40, reps:5, amrap:false),
                     .init(pct:0.50, reps:5, amrap:false),
                     .init(pct:0.60, reps:5, amrap:false)],
                    false,
                    "Deload: 60% × 5")
        default:
            // Week 1: 65×5, 75×5, 85×5+
            return ([.init(pct:0.65, reps:5, amrap:false),
                     .init(pct:0.75, reps:5, amrap:false),
                     .init(pct:0.85, reps:5, amrap:true)],
                    true,
                    "85% × 5+")
        }
    }
    
    private func isAssistCompleted(_ n: Int) -> Bool {
        switch (selectedLift, n) {
        case (.squat, 1): return assist1DoneSquat
        case (.squat, 2): return assist2DoneSquat
        case (.squat, 3): return assist3DoneSquat
        case (.bench, 1): return assist1DoneBench
        case (.bench, 2): return assist2DoneBench
        case (.bench, 3): return assist3DoneBench
        case (.deadlift, 1): return assist1DoneDeadlift
        case (.deadlift, 2): return assist2DoneDeadlift
        case (.deadlift, 3): return assist3DoneDeadlift
        case (.row, 1): return assist1DoneRow
        case (.row, 2): return assist2DoneRow
        case (.row, 3): return assist3DoneRow
        default: return false
        }
    }
    
    private func assistWeightBinding(for lift: Lift) -> Binding<Double> {
        switch lift {
        case .squat:    return $assistWeightSquat
        case .bench:    return $assistWeightBench
        case .deadlift: return $assistWeightDeadlift
        case .row:    return $assistWeightRow
        }
    }
    
    private func assistSetBinding(_ n: Int) -> Binding<Bool> {
        switch (selectedLift, n) {
        case (.squat, 1): return $assist1DoneSquat
        case (.squat, 2): return $assist2DoneSquat
        case (.squat, 3): return $assist3DoneSquat
        case (.bench, 1): return $assist1DoneBench
        case (.bench, 2): return $assist2DoneBench
        case (.bench, 3): return $assist3DoneBench
        case (.deadlift, 1): return $assist1DoneDeadlift
        case (.deadlift, 2): return $assist2DoneDeadlift
        case (.deadlift, 3): return $assist3DoneDeadlift
        case (.row, 1): return $assist1DoneRow
        case (.row, 2): return $assist2DoneRow
        case (.row, 3): return $assist3DoneRow
        default: return .constant(false)
        }
    }
    
    private func setBinding(_ num: Int) -> Binding<Bool> {
        switch selectedLift {
        case .squat:
            switch num {
            case 1: return $set1DoneSquat
            case 2: return $set2DoneSquat
            case 3: return $set3DoneSquat
            case 4: return $bbb1DoneSquat
            case 5: return $bbb2DoneSquat
            case 6: return $bbb3DoneSquat
            case 7: return $bbb4DoneSquat
            case 8: return $bbb5DoneSquat
            default: return .constant(false)
            }
        case .bench:
            switch num {
            case 1: return $set1DoneBench
            case 2: return $set2DoneBench
            case 3: return $set3DoneBench
            case 4: return $bbb1DoneBench
            case 5: return $bbb2DoneBench
            case 6: return $bbb3DoneBench
            case 7: return $bbb4DoneBench
            case 8: return $bbb5DoneBench
            default: return .constant(false)
            }
        case .deadlift:
            switch num {
            case 1: return $set1DoneDeadlift
            case 2: return $set2DoneDeadlift
            case 3: return $set3DoneDeadlift
            case 4: return $bbb1DoneDeadlift
            case 5: return $bbb2DoneDeadlift
            case 6: return $bbb3DoneDeadlift
            case 7: return $bbb4DoneDeadlift
            case 8: return $bbb5DoneDeadlift
            default: return .constant(false)
            }
        case .row:
            switch num {
            case 1: return $set1DoneRow
            case 2: return $set2DoneRow
            case 3: return $set3DoneRow
            case 4: return $bbb1DoneRow
            case 5: return $bbb2DoneRow
            case 6: return $bbb3DoneRow
            case 7: return $bbb4DoneRow
            case 8: return $bbb5DoneRow
            default: return .constant(false)
            }
        }
    }
    
    private func platesForEZ(target: Double) -> [Double] {
        let ezBarWeight = 25.0
        guard target >= ezBarWeight else { return [] }
        var remainingPerSide = (target - ezBarWeight) / 2.0
        var out: [Double] = []
        for p in plateInventory.sorted(by: >) {
            while remainingPerSide + 1e-9 >= p {
                out.append(p)
                remainingPerSide -= p
            }
        }
        return out
    }
    
    private func int(_ x: Double) -> String {
        x.rounded() == x ? String(format: "%.0f", x) : String(format: "%.1f", x)
    }
    
    private func roundToInc(_ x: Double) -> Double {
        (x / roundTo).rounded() * roundTo
    }
    
    private func platesFor(target: Double) -> [Double] {
        guard target >= barWeight else { return [] }
        var remainingPerSide = (target - barWeight) / 2.0
        var out: [Double] = []
        for p in plateInventory.sorted(by: >) {
            while remainingPerSide + 1e-9 >= p {
                out.append(p)
                remainingPerSide -= p
            }
        }
        return out
    }
    
    private func resetCurrentLift() {
        switch selectedLift {
        case .squat:
            set1DoneSquat = false
            set2DoneSquat = false
            set3DoneSquat = false
            bbb1DoneSquat = false
            bbb2DoneSquat = false
            bbb3DoneSquat = false
            bbb4DoneSquat = false
            bbb5DoneSquat = false
            amrapRepsSquat = 0
            // assistance
            assist1DoneSquat = false
            assist2DoneSquat = false
            assist3DoneSquat = false
            // optional: reset weight to default for this lift
            assistWeightSquat = 0
            
        case .bench:
            set1DoneBench = false
            set2DoneBench = false
            set3DoneBench = false
            bbb1DoneBench = false
            bbb2DoneBench = false
            bbb3DoneBench = false
            bbb4DoneBench = false
            bbb5DoneBench = false
            amrapRepsBench = 0
            // assistance
            assist1DoneBench = false
            assist2DoneBench = false
            assist3DoneBench = false
            // optional: reset weight; LTE defaults to EZ bar 25 + suggest 40 total? keep your 65 default if you prefer
            assistWeightBench = 65
            
        case .deadlift:
            set1DoneDeadlift = false
            set2DoneDeadlift = false
            set3DoneDeadlift = false
            bbb1DoneDeadlift = false
            bbb2DoneDeadlift = false
            bbb3DoneDeadlift = false
            bbb4DoneDeadlift = false
            bbb5DoneDeadlift = false
            amrapRepsDeadlift = 0
            // assistance
            assist1DoneDeadlift = false
            assist2DoneDeadlift = false
            assist3DoneDeadlift = false
            // optional
            assistWeightDeadlift = 0
            
        case .row:
            set1DoneRow = false
            set2DoneRow = false
            set3DoneRow = false
            bbb1DoneRow = false
            bbb2DoneRow = false
            bbb3DoneRow = false
            bbb4DoneRow = false
            bbb5DoneRow = false
            amrapRepsRow = 0
            // assistance
            assist1DoneRow = false
            assist2DoneRow = false
            assist3DoneRow = false
            // optional
            assistWeightRow = 0
        }
        
        workoutNotes = ""
    }
    
    // Returns whether a given row is completed for the currently selected lift
    private func isCompleted(_ num: Int) -> Bool {
        switch selectedLift {
        case .squat:
            switch num {
            case 1: return set1DoneSquat
            case 2: return set2DoneSquat
            case 3: return set3DoneSquat
            case 4: return bbb1DoneSquat
            case 5: return bbb2DoneSquat
            case 6: return bbb3DoneSquat
            case 7: return bbb4DoneSquat
            case 8: return bbb5DoneSquat
            default: return false
            }
        case .bench:
            switch num {
            case 1: return set1DoneBench
            case 2: return set2DoneBench
            case 3: return set3DoneBench
            case 4: return bbb1DoneBench
            case 5: return bbb2DoneBench
            case 6: return bbb3DoneBench
            case 7: return bbb4DoneBench
            case 8: return bbb5DoneBench
            default: return false
            }
        case .deadlift:
            switch num {
            case 1: return set1DoneDeadlift
            case 2: return set2DoneDeadlift
            case 3: return set3DoneDeadlift
            case 4: return bbb1DoneDeadlift
            case 5: return bbb2DoneDeadlift
            case 6: return bbb3DoneDeadlift
            case 7: return bbb4DoneDeadlift
            case 8: return bbb5DoneDeadlift
            default: return false
            }
        case .row:
            switch num {
            case 1: return set1DoneRow
            case 2: return set2DoneRow
            case 3: return set3DoneRow
            case 4: return bbb1DoneRow
            case 5: return bbb2DoneRow
            case 6: return bbb3DoneRow
            case 7: return bbb4DoneRow
            case 8: return bbb5DoneRow
            default: return false
            }
        }
    }
    
    // Numeric AMRAP reps for the current lift
    private var currentAMRAP: Int {
        switch selectedLift {
        case .squat: return amrapRepsSquat
        case .bench: return amrapRepsBench
        case .deadlift: return amrapRepsDeadlift
        case .row: return amrapRepsRow
        }
    }
    
    private func currentWorkoutMetrics() -> (est: Double, totalVol: Int, mainVol: Int, bbbVol: Int, assistVol: Int) {
        let scheme = weekScheme(currentWeek)
        let tmSel = tmFor(selectedLift)
        
        // MAIN sets (use weekScheme, only AMRAP if scheme says so)
        func mainSetVol(_ idx: Int) -> Double {
            let s = scheme.main[idx]
            let w = roundToInc(tmSel * s.pct)
            let reps = s.amrap ? Double(max(currentAMRAP, 0)) : Double(s.reps)
            return w * reps
        }
        let mainVol = Int(mainSetVol(0) + mainSetVol(1) + mainSetVol(2))
        
        // BBB volume only if allowed
        let bbbW = roundToInc(tmSel * bbbPct)
        let bbbPerSet = scheme.showBBB ? bbbW * 10 : 0
        let b1 = isCompleted(4) ? bbbPerSet : 0
        let b2 = isCompleted(5) ? bbbPerSet : 0
        let b3 = isCompleted(6) ? bbbPerSet : 0
        let b4 = isCompleted(7) ? bbbPerSet : 0
        let b5 = isCompleted(8) ? bbbPerSet : 0
        let bbbVol = Int(b1 + b2 + b3 + b4 + b5)
        
        // Assistance volume only if allowed
        let assistDef = assistanceFor(selectedLift)
        let assistW = max(assistWeightBinding(for: selectedLift).wrappedValue, assistDef.defaultBarWeight)
        let a1 = (scheme.showBBB && isAssistCompleted(1)) ? assistW * Double(assistDef.defaultReps) : 0
        let a2 = (scheme.showBBB && isAssistCompleted(2)) ? assistW * Double(assistDef.defaultReps) : 0
        let a3 = (scheme.showBBB && isAssistCompleted(3)) ? assistW * Double(assistDef.defaultReps) : 0
        let assistVol = Int(a1 + a2 + a3)
        
        let totalVol = mainVol + bbbVol + assistVol
        
        // Est 1RM: only meaningful on AMRAP weeks (s.main[2] is the top set)
        let top = scheme.main[2]
        let est: Double = {
            guard top.amrap, currentAMRAP > 0 else { return 0 }
            let w = roundToInc(tmSel * top.pct)
            let e = w * (1 + Double(currentAMRAP) / 30.0)
            return roundToInc(e)
        }()
        
        return (est, totalVol, mainVol, bbbVol, assistVol)
    }
    
    // 1 Hz tick
    private let tick = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    private func startTimer(seconds: Int) {
        timerEnd = Date().addingTimeInterval(TimeInterval(seconds))
        timerRemaining = seconds
        timerRunning = true
        requestNotifsIfNeeded()
        scheduleDoneNotification(in: seconds)
    }
    
    private func pauseTimer() {
        timerRunning = false
        // keep remaining; don't clear end so we can resume if you want to extend later
        timerEnd = nil
        cancelDoneNotification()
    }
    
    private func resetTimer() {
        timerRunning = false
        timerEnd = nil
        timerRemaining = 0
        cancelDoneNotification()
    }
    
    // format mm:ss
    private func mmss(_ s: Int) -> String {
        let m = s / 60, r = s % 60
        return String(format: "%d:%02d", m, r)
    }
    
    private func requestNotifsIfNeeded() {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { s in
            if s.authorizationStatus == .notDetermined {
                center.requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
            }
        }
    }
    
    private func scheduleDoneNotification(in seconds: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Rest finished"
        content.body = "Time to lift \(selectedLift.label)."
        content.sound = UNNotificationSound.default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(seconds), repeats: false)
        let req = UNNotificationRequest(identifier: "rest-timer", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(req)
    }
    
    private func cancelDoneNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["rest-timer"])
    }
    
    // AMRAP helpers
    private func repsText(for lift: Lift) -> String {
        let r: Int
        switch lift {
        case .squat: r = amrapRepsSquat
        case .bench: r = amrapRepsBench
        case .deadlift: r = amrapRepsDeadlift
        case .row: r = amrapRepsRow
        }
        return r == 0 ? "" : String(r)
    }
    
    private func saveReps(_ text: String, for lift: Lift) {
        let r = Int(text) ?? 0
        switch lift {
        case .squat: amrapRepsSquat = r
        case .bench: amrapRepsBench = r
        case .deadlift: amrapRepsDeadlift = r
        case .row: amrapRepsRow = r
        }
    }
    
    private func est1RM(for lift: Lift, weight: Double) -> Double {
        let reps: Int
        switch lift {
        case .squat: reps = amrapRepsSquat
        case .bench: reps = amrapRepsBench
        case .deadlift: reps = amrapRepsDeadlift
        case .row: reps = amrapRepsRow
        }
        guard reps > 0 else { return 0 }
        let est = weight * (1 + Double(reps) / 30.0) // Epley
        return roundToInc(est)
    }
    
    private struct HistorySheet: View {
        @State private var entries: [WorkoutEntry] = []
        @State private var expanded: Set<UUID> = []
        
        var body: some View {
            NavigationStack {
                List {
                    if entries.isEmpty {
                        ContentUnavailableView("No saved workouts yet",
                                               systemImage: "tray",
                                               description: Text("Tap “Finish Workout” after a session to log it here."))
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
                                
                                // 👇 Notes preview (now 'e' is in scope)
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
                                // Tapping the row toggles too
                                if expanded.contains(e.id) { expanded.remove(e.id) } else { expanded.insert(e.id) }
                            }
                            // 👇 Swipe left to delete
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
    
    // MARK: - Rows
    
    private struct SetRow: View {
        let label: String
        let weight: Double
        let perSide: [Double]
        @Binding var done: Bool
        var onCheck: ((Bool) -> Void)? = nil
        
        var body: some View {
            HStack(alignment: .firstTextBaseline) {
                Toggle(isOn: $done) { Text(label) } // default iOS toggle style
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
            // fire when the toggle changes
            .onChange(of: done) { _, new in
                onCheck?(new)
            }
        }
        
        private func plateList(_ ps: [Double]) -> String {
            ps.map { $0.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int($0))" : String(format: "%.1f", $0) }
                .joined(separator: ", ")
        }
    }
    
    // 1. Fix AMRAPRow - Remove nested toolbar
    private struct AMRAPRow: View {
        let label: String
        let weight: Double
        let perSide: [Double]
        @Binding var done: Bool
        @Binding var reps: String
        let est1RM: Double
        var onCheck: ((Bool) -> Void)? = nil
        @FocusState private var isFocused: Bool  // Add this
        
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
                .onChange(of: done) { _, new in
                    onCheck?(new)
                }
                
                HStack {
                    Text("AMRAP reps:")
                    TextField("e.g. 8", text: $reps)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                        .focused($isFocused)  // Use FocusState instead
                        .onSubmit {
                            isFocused = false
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
            ps.map { $0.truncatingRemainder(dividingBy: 1) == 0
                ? "\(Int($0))"
                : String(format: "%.1f", $0)
            }.joined(separator: ", ")
        }
    }
    
    // MARK: - Settings
    
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
                        }
                        HStack {
                            Text("BBB / accessory")
                            Spacer()
                            TextField("180", text: $tmpTimerBBB)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
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
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Done") {
                            focusedField = nil
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
                            if let v = Double(tmpRow)    { tmRow = v }
                            if let v = Double(tmpBarWeight){ barWeight = v }
                            if let v = Double(tmpRoundTo)  { roundTo = v }
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
}
