import SwiftUI

struct WorkoutBlock: View {
    // Inputs from ContentView
    @Binding var selectedLift: Lift
    @Binding var currentWeek: Int
    @Binding var workoutNotes: String

    // Focus bindings coming from ContentView
    let notesFocused: FocusState<Bool>.Binding
    let amrapFocused: FocusState<Bool>.Binding

    // Shared state/services
    let timer: TimerManager
    let program: ProgramEngine
    let calculator: PlateCalculator
    let barWeightForSelectedLift: Double
    let roundTo: Double
    let bbbPct: Double
    let timerRegularSec: Int
    let timerBBBsec: Int

    // Helpers provided by ContentView so state stays single-source-of-truth
    // NOTE: now returns AmrapEstimate (value + note) instead of Double
    let est1RM: (Lift, Double) -> AmrapEstimate
    let setBinding: (Int) -> Binding<Bool>
    let tmFor: (Lift) -> Double

    // Live AMRAP text from ContentView
    @Binding var liveRepsText: String

    // STATE SOURCE passed in explicitly
    @ObservedObject var workoutState: WorkoutStateManager

    // Timer gating
    let allowTimerStarts: Bool
    let armTimers: () -> Void

    // NEW: Whether this workout has been marked as finished
    let isWorkoutFinished: Bool
    
    // Passed in from ContentView so we can render formula in use.
    let currentFormula: OneRepMaxFormula

    var body: some View {
        let scheme = program.weekScheme(for: currentWeek)
        let tm     = tmFor(selectedLift)
        let refreshID = "\(selectedLift.rawValue)-\(currentWeek)"

        VStack(alignment: .leading, spacing: 12) {
            header
            liftPicker
            warmupLink(tm: tm, scheme: scheme)
            mainSets(tm: tm, scheme: scheme, refreshID: refreshID)
            NotesField(text: $workoutNotes, focused: notesFocused)
            RestTimerCard(timer: timer, regular: timerRegularSec, bbb: timerBBBsec)
            bbbSets(tm: tm, scheme: scheme, refreshID: refreshID)
        }
        .cardStyle()
        .padding(.horizontal)
    }

    // MARK: - Sections

    private var header: some View {
        HStack {
            Text("Week \(currentWeek) Workout")
                .font(.title3.weight(.bold))
            Spacer()
            Picker("Week", selection: $currentWeek) {
                Text("1").tag(1); Text("2").tag(2); Text("3").tag(3); Text("4").tag(4)
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 220)
        }
    }

    private var liftPicker: some View {
        Picker("Lift", selection: $selectedLift) {
            ForEach(Lift.allCases) { Text($0.label).tag($0) }
        }
        .pickerStyle(.segmented)
    }

    @ViewBuilder
    private func warmupLink(tm: Double, scheme: WeekSchemeResult) -> some View {
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
                .accessibilityHint("Shows plate math and sets for ramping up.")
        }
        .buttonStyle(.borderedProminent)
    }

    @ViewBuilder
    private func mainSets(tm: Double, scheme: WeekSchemeResult, refreshID: String) -> some View {
        let s0 = scheme.main[0], s1 = scheme.main[1], s2 = scheme.main[2]
        let w0 = calculator.round(tm * s0.pct)
        let w1 = calculator.round(tm * s1.pct)
        let w2 = calculator.round(tm * s2.pct)

        SetRow(
            label: "\(Int(s0.pct * 100))% × \(s0.reps)",
            weight: w0,
            perSide: calculator.plates(target: w0),
            done: setBinding(1),
            onCheck: { checked in
                if checked && !isWorkoutFinished {
                    armTimers()
                    if allowTimerStarts { timer.start(seconds: timerRegularSec) }
                }
            },
            refreshID: refreshID
        )

        SetRow(
            label: "\(Int(s1.pct * 100))% × \(s1.reps)",
            weight: w1,
            perSide: calculator.plates(target: w1),
            done: setBinding(2),
            onCheck: { checked in
                if checked && !isWorkoutFinished {
                    armTimers()
                    if allowTimerStarts { timer.start(seconds: timerRegularSec) }
                }
            },
            refreshID: refreshID
        )

        if s2.amrap {
            // Ask for the full estimate (value + note)
            let r = est1RM(selectedLift, w2)
            let capText: String? = {
                switch r.note {
                case .none:
                    return nil
                case .lowConfidence:
                    return "Estimate low confidence (high reps)."
                case .capped(let cap):
                    return "Estimated using \(cap) reps (capped)."
                case .invalidTooManyReps(let actual):
                    return "Too many reps (\(actual)) to estimate 1RM."
                }
            }()

            AMRAPRow(
                label: "\(Int(s2.pct * 100))% × \(s2.reps)+",
                weight: w2,
                perSide: calculator.plates(target: w2),
                done: setBinding(3),
                reps: $liveRepsText,
                est1RM: r.e1RM,
                capNote: capText,
                onCheck: { checked in
                    if checked && !isWorkoutFinished {
                        armTimers()
                        if allowTimerStarts { timer.start(seconds: timerRegularSec) }
                    }
                },
                focus: amrapFocused,
                refreshID: refreshID,
                currentFormula: currentFormula
            )
        } else {
            SetRow(
                label: "\(Int(s2.pct * 100))% × \(s2.reps)",
                weight: w2,
                perSide: calculator.plates(target: w2),
                done: setBinding(3),
                onCheck: { checked in
                    if checked && !isWorkoutFinished {
                        armTimers()
                        if allowTimerStarts { timer.start(seconds: timerRegularSec) }
                    }
                },
                refreshID: refreshID
            )
            Text("Deload week: skip BBB/assistance and add 10–20 min easy cardio.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func bbbSets(tm: Double, scheme: WeekSchemeResult, refreshID: String) -> some View {
        if scheme.showBBB {
            Divider().padding(.vertical, 4)
            let defaultBBBWeight = calculator.round(tm * bbbPct)

            Text(selectedLift == .row
                    ? "Assistance — Lat Pulldown 5×10 @ \(Int(bbbPct * 100))% TM (Row)"
                    : "Assistance — BBB 5×10 @ \(Int(bbbPct * 100))% TM")
                .font(.headline)

            ForEach(1...5, id: \.self) { bbbSetNum in
                let setNum = bbbSetNum + 3 // Sets 4–8 in main tracking
                BBBSetRow(
                    setNumber: bbbSetNum,
                    defaultWeight: defaultBBBWeight,
                    defaultReps: 10,
                    done: setBinding(setNum),
                    currentWeight: Binding(
                        get: {
                            workoutState.getBBBWeight(
                                lift: selectedLift.rawValue,
                                week: currentWeek,
                                set: bbbSetNum
                            ) ?? defaultBBBWeight
                        },
                        set: { newVal in
                            if abs(newVal - defaultBBBWeight) < 0.1 {
                                workoutState.setBBBWeight(
                                    lift: selectedLift.rawValue,
                                    week: currentWeek,
                                    set: bbbSetNum,
                                    weight: nil
                                )
                            } else {
                                workoutState.setBBBWeight(
                                    lift: selectedLift.rawValue,
                                    week: currentWeek,
                                    set: bbbSetNum,
                                    weight: newVal
                                )
                            }
                            // …then cascade forward to remaining (not-done) sets
                            cascadeBBBWeight(from: bbbSetNum, newWeight: newVal, defaultWeight: defaultBBBWeight)
                        }
                    ),
                    currentReps: Binding(
                        get: {
                            workoutState.getBBBReps(
                                lift: selectedLift.rawValue,
                                week: currentWeek,
                                set: bbbSetNum
                            ) ?? 10
                        },
                        set: { newVal in
                            if newVal == 10 {
                                workoutState.setBBBReps(
                                    lift: selectedLift.rawValue,
                                    week: currentWeek,
                                    set: bbbSetNum,
                                    reps: nil
                                )
                            } else {
                                workoutState.setBBBReps(
                                    lift: selectedLift.rawValue,
                                    week: currentWeek,
                                    set: bbbSetNum,
                                    reps: newVal
                                )
                            }
                            // …then cascade forward
                            cascadeBBBReps(from: bbbSetNum, newReps: newVal, defaultReps: 10)
                        }
                    ),
                    perSide: selectedLift == .row
                        ? []
                        : calculator.plates(
                            target: workoutState.getBBBWeight(
                                lift: selectedLift.rawValue,
                                week: currentWeek,
                                set: bbbSetNum
                            ) ?? defaultBBBWeight
                        ),
                    roundTo: roundTo,
                    onCheck: { checked in
                        if checked && !isWorkoutFinished {
                            armTimers()
                            if allowTimerStarts { timer.start(seconds: timerBBBsec) }
                        }
                    },
                    refreshID: refreshID
                )
            }
        } else {
            Text("Deload week: skip BBB/assistance and add ~30 min easy cardio.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Cascade helpers (BBB)
    private func cascadeBBBWeight(from startBBBSet: Int, newWeight: Double, defaultWeight: Double) {
        // BBB sets are numbered 1...5; their "main tracking" set index is +3 (4...8)
        for n in startBBBSet...5 {
            let mainSetNum = n + 3
            // skip sets already marked done
            guard !workoutState.getSetComplete(lift: selectedLift.rawValue, week: currentWeek, set: mainSetNum) else { continue }

            if abs(newWeight - defaultWeight) < 0.1 {
                workoutState.setBBBWeight(lift: selectedLift.rawValue, week: currentWeek, set: n, weight: nil)
            } else {
                workoutState.setBBBWeight(lift: selectedLift.rawValue, week: currentWeek, set: n, weight: newWeight)
            }
        }
    }

    private func cascadeBBBReps(from startBBBSet: Int, newReps: Int, defaultReps: Int = 10) {
        for n in startBBBSet...5 {
            let mainSetNum = n + 3
            guard !workoutState.getSetComplete(lift: selectedLift.rawValue, week: currentWeek, set: mainSetNum) else { continue }

            if newReps == defaultReps {
                workoutState.setBBBReps(lift: selectedLift.rawValue, week: currentWeek, set: n, reps: nil)
            } else {
                workoutState.setBBBReps(lift: selectedLift.rawValue, week: currentWeek, set: n, reps: newReps)
            }
        }
    }
}
