import SwiftUI

struct AssistanceBlock: View {
    // Inputs
    @Binding var selectedLift: Lift
    let currentWeek: Int
    let program: ProgramEngine
    let workoutState: WorkoutStateManager
    let implements: ImplementWeights
    let calculator: PlateCalculator
    let roundTo: Double
    let timer: TimerManager
    let timerBBBsec: Int

    /// Map the selected main lift to the chosen assistance exercise
    let assistanceFor: (Lift) -> AssistanceExercise

    /// Binding provider for assist set completion (sets 1...3)
    let assistSetBinding: (Int) -> Binding<Bool>

    /// Legacy default weights per main lift (e.g. 65 for bench); return nil if none.
    let legacyAssistDefault: (Lift) -> Double?

    /// Timer gating: allow + explicit arming (prevents auto-start on app launch)
    let allowTimerStarts: Bool
    let armTimers: () -> Void

    /// NEW: Whether this workout has been marked as finished
    let isWorkoutFinished: Bool

    // NEW: access to training maxes
    let tmFor: (Lift) -> Double
    
    let startRest: (Int, Bool) -> Void

    var body: some View {
        let scheme = program.weekScheme(for: currentWeek)
        let ex = assistanceFor(selectedLift)
        let isSSBGM = (ex.id == "ssb_gm")
        let isDBRDL = (selectedLift == .deadlift && ex.id == "db_rdl")
        let deadliftTM = tmFor(.deadlift)
        let refreshID = "\(selectedLift.rawValue)-\(currentWeek)"

        // Which assistance use a barbell (plates + implement)?
        let barAssistanceIDs: Set<String> = [
            "front_squat", "paused_squat", "close_grip", "triceps_ext", "ssb_gm"
        ]
        let usesBarbell = barAssistanceIDs.contains(ex.id)

        // Per-exercise implement (e.g. 25 lb EZ-bar for triceps_ext)
        let implementW = implements.weight(for: ex.id)

        return VStack(alignment: .leading, spacing: 12) {
            if scheme.showBBB {
                Divider().padding(.vertical, 4) // match WorkoutBlock

                // Whether the block uses weight at all
                let hasBarWeight: Bool = {
                    if usesBarbell { return true }
                    if ex.allowWeightToggle {
                        return workoutState.getAssistUseWeight(lift: selectedLift.rawValue, week: currentWeek)
                    }
                    return ex.defaultWeight > 0
                }()

                let defaultWeight: Double = {
                    if isDBRDL {
                        return Double(recommendedDBRDLPerHand(deadliftTM: deadliftTM, roundTo: roundTo))
                    } else if isSSBGM {
                        let dlTM = tmFor(.deadlift)
                        let w = recommendedSSBGMWeight(deadliftTM: dlTM, barWeight: implementW, roundTo: roundTo)
                        return Double(w)
                    } else if usesBarbell {
                        let legacy = legacyAssistDefault(selectedLift)
                        let base = legacy ?? (ex.defaultWeight > 0 ? ex.defaultWeight : implementW)
                        return max(base, implementW)
                    } else if ex.allowWeightToggle {
                        return workoutState.getAssistUseWeight(lift: selectedLift.rawValue, week: currentWeek)
                            ? ex.toggledWeight
                            : ex.defaultWeight
                    } else {
                        return ex.defaultWeight
                    }
                }()

                // Only show the dumbbell toggle for non-barbell exercises that allow it
                let showToggle = ex.allowWeightToggle && !usesBarbell && !isDBRDL

                VStack(alignment: .leading, spacing: 8) {
                    Text("Assistance — \(ex.name)")
                        .font(.headline)

                    if showToggle {
                        Toggle(isOn: Binding(
                            get: { workoutState.getAssistUseWeight(lift: selectedLift.rawValue, week: currentWeek) },
                            set: { workoutState.setAssistUseWeight(lift: selectedLift.rawValue, week: currentWeek, useWeight: $0) }
                        )) {
                            Text("Use dumbbells")
                                .font(.subheadline)
                        }
                        .toggleStyle(.switch)
                    }

                    // TM-based hints
                    if isSSBGM {
                        let dlTM = tmFor(.deadlift)
                        let suggest = recommendedSSBGMWeight(deadliftTM: dlTM, barWeight: implementW, roundTo: roundTo)
                        Text("Suggested: \(suggest) lb total · 3×8–10")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if isDBRDL {
                        let dlTM = tmFor(.deadlift)
                        let suggest = recommendedDBRDLPerHand(deadliftTM: dlTM, roundTo: roundTo)
                        Text("Suggested: \(suggest) lb per hand · 4×8–12")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                let ex = assistanceFor(selectedLift)

                // Compute the default assistance weight ONCE for this exercise/workout
                let defaultAssistW: Double = {
                    if ex.defaultWeight > 0 {
                        return ex.defaultWeight
                    }
                    if ex.allowWeightToggle && workoutState.getAssistUseWeight(lift: selectedLift.rawValue, week: currentWeek) {
                        return ex.toggledWeight
                    }
                    return 0
                }()

                ForEach(1...3, id: \.self) { setNum in
                    AssistSetRow(
                        setNumber: setNum,
                        defaultWeight: defaultWeight,
                        defaultReps: ex.defaultReps,
                        hasBarWeight: hasBarWeight,
                        usesBarbell: usesBarbell,
                        done: assistSetBinding(setNum),
                        currentWeight: Binding(
                            get: {
                                let saved = workoutState.getAssistWeight(
                                    lift: selectedLift.rawValue,
                                    week: currentWeek,
                                    set: setNum
                                )
                                let v = saved ?? defaultWeight
                                return usesBarbell ? max(v, implementW) : v
                            },
                            set: { newVal in
                                let clamped = usesBarbell ? max(newVal, implementW) : newVal
                                if abs(clamped - defaultWeight) < 0.1 {
                                    workoutState.setAssistWeight(
                                        lift: selectedLift.rawValue,
                                        week: currentWeek,
                                        set: setNum,
                                        weight: nil
                                    )
                                } else {
                                    workoutState.setAssistWeight(
                                        lift: selectedLift.rawValue,
                                        week: currentWeek,
                                        set: setNum,
                                        weight: clamped
                                    )
                                }
                                // Cascade forward to remaining, not-done sets
                                cascadeAssistWeight(from: setNum, newWeight: newVal, defaultWeight: defaultAssistW)
                            }
                        ),
                        currentReps: Binding(
                            get: {
                                workoutState.getAssistReps(
                                    lift: selectedLift.rawValue,
                                    week: currentWeek,
                                    set: setNum
                                ) ?? ex.defaultReps
                            },
                            set: { newVal in
                                if newVal == ex.defaultReps {
                                    workoutState.setAssistReps(
                                        lift: selectedLift.rawValue,
                                        week: currentWeek,
                                        set: setNum,
                                        reps: nil
                                    )
                                } else {
                                    workoutState.setAssistReps(
                                        lift: selectedLift.rawValue,
                                        week: currentWeek,
                                        set: setNum,
                                        reps: newVal
                                    )
                                }
                                // Cascade forward to remaining, not-done sets
                                cascadeAssistReps(from: setNum, newReps: newVal, defaultReps: ex.defaultReps)
                            }
                        ),
                        perSide: (usesBarbell && hasBarWeight)
                            ? calculator.plates(
                                target: {
                                    let saved = workoutState.getAssistWeight(
                                        lift: selectedLift.rawValue,
                                        week: currentWeek,
                                        set: setNum
                                    ) ?? defaultWeight
                                    let v = usesBarbell ? max(saved, implementW) : saved
                                    return v
                                }(),
                                barWeight: implementW
                            )
                            : [],
                        roundTo: roundTo,
                        onCheck: { checked in
                            if checked && !isWorkoutFinished {startRest(timerBBBsec, true) }
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
        .cardStyle()
        .padding(.horizontal)
    }
    
    // MARK: - Cascade helpers (Assistance)
    private func cascadeAssistWeight(from startSet: Int, newWeight: Double, defaultWeight: Double) {
        for n in startSet...3 {
            guard !workoutState.getAssistComplete(lift: selectedLift.rawValue, week: currentWeek, set: n) else { continue }

            if abs(newWeight - defaultWeight) < 0.1 {
                workoutState.setAssistWeight(lift: selectedLift.rawValue, week: currentWeek, set: n, weight: nil)
            } else {
                workoutState.setAssistWeight(lift: selectedLift.rawValue, week: currentWeek, set: n, weight: newWeight)
            }
        }
    }

    private func cascadeAssistReps(from startSet: Int, newReps: Int, defaultReps: Int) {
        for n in startSet...3 {
            guard !workoutState.getAssistComplete(lift: selectedLift.rawValue, week: currentWeek, set: n) else { continue }

            if newReps == defaultReps {
                workoutState.setAssistReps(lift: selectedLift.rawValue, week: currentWeek, set: n, reps: nil)
            } else {
                workoutState.setAssistReps(lift: selectedLift.rawValue, week: currentWeek, set: n, reps: newReps)
            }
        }
    }
}
