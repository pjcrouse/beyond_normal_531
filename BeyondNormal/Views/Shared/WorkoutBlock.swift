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
    let est1RM: (Lift, Double) -> Double
    let setBinding: (Int) -> Binding<Bool>

    // Live AMRAP text from ContentView
    @Binding var liveRepsText: String

    // STATE SOURCE passed in explicitly
    @ObservedObject var workoutState: WorkoutStateManager

    var body: some View {
        let scheme = program.weekScheme(for: currentWeek)
        let tm     = tmFor(selectedLift)

        VStack(alignment: .leading, spacing: 12) {
            header
            liftPicker
            warmupLink(tm: tm, scheme: scheme)
            mainSets(tm: tm, scheme: scheme)
            NotesField(text: $workoutNotes, focused: notesFocused)
            RestTimerCard(timer: timer, regular: timerRegularSec, bbb: timerBBBsec)
            bbbSets(tm: tm, scheme: scheme)
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
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
        }
        .buttonStyle(.borderedProminent)
    }

    @ViewBuilder
    private func mainSets(tm: Double, scheme: WeekSchemeResult) -> some View {
        let s0 = scheme.main[0], s1 = scheme.main[1], s2 = scheme.main[2]
        let w0 = calculator.round(tm * s0.pct)
        let w1 = calculator.round(tm * s1.pct)
        let w2 = calculator.round(tm * s2.pct)

        SetRow(
            label: "\(Int(s0.pct * 100))% × \(s0.reps)",
            weight: w0,
            perSide: calculator.plates(target: w0),
            done: setBinding(1),
            onCheck: { if $0 { timer.start(seconds: timerRegularSec) } }
        )

        SetRow(
            label: "\(Int(s1.pct * 100))% × \(s1.reps)",
            weight: w1,
            perSide: calculator.plates(target: w1),
            done: setBinding(2),
            onCheck: { if $0 { timer.start(seconds: timerRegularSec) } }
        )

        if s2.amrap {
            AMRAPRow(
                label: "\(Int(s2.pct * 100))% × \(s2.reps)+",
                weight: w2,
                perSide: calculator.plates(target: w2),
                done: setBinding(3),
                reps: $liveRepsText,
                est1RM: est1RM(selectedLift, w2),
                onCheck: { if $0 { timer.start(seconds: timerRegularSec) } },
                focus: amrapFocused
            )
        } else {
            SetRow(
                label: "\(Int(s2.pct * 100))% × \(s2.reps)",
                weight: w2,
                perSide: calculator.plates(target: w2),
                done: setBinding(3),
                onCheck: { if $0 { timer.start(seconds: timerRegularSec) } }
            )
            Text("Deload week: skip BBB/assistance and add 10–20 min easy cardio.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func bbbSets(tm: Double, scheme: WeekSchemeResult) -> some View {
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
                    onCheck: { if $0 { timer.start(seconds: timerBBBsec) } }
                )
            }
        } else {
            Text("Deload week: skip BBB/assistance and add ~30 min easy cardio.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Local helpers (read TMs from AppStorage)
    private func tmFor(_ lift: Lift) -> Double {
        switch lift {
        case .squat: return AppStorageBacked.tmSquat
        case .bench: return AppStorageBacked.tmBench
        case .deadlift: return AppStorageBacked.tmDeadlift
        case .row: return AppStorageBacked.tmRow
        }
    }
}

// Tiny shim so WorkoutBlock can read TM without duplicating state.
private enum AppStorageBacked {
    @AppStorage("tm_squat")    static var tmSquat: Double = 315
    @AppStorage("tm_bench")    static var tmBench: Double = 225
    @AppStorage("tm_deadlift") static var tmDeadlift: Double = 405
    @AppStorage("tm_row")      static var tmRow: Double = 185
}
