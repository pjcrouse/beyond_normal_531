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

    var body: some View {
        let scheme = program.weekScheme(for: currentWeek)
        let ex = assistanceFor(selectedLift)
        let refreshID = "\(selectedLift.rawValue)-\(currentWeek)"

        // Which assistance use a barbell (plates + implement)?
        // Include triceps_ext so Lying Triceps Extension uses the EZ-bar implement.
        let barAssistanceIDs: Set<String> = [
            "front_squat", "paused_squat", "close_grip", "triceps_ext"
        ]
        let usesBarbell = barAssistanceIDs.contains(ex.id)

        // Per-exercise implement (e.g. 25 lb EZ-bar for triceps_ext)
        let implementW = implements.weight(for: ex.id)

        return Group {
            if scheme.showBBB {
                Divider().padding(.vertical, 6)

                // Whether the block uses weight at all
                // Barbell assistance: always true. Otherwise depend on toggle/defaults.
                let hasBarWeight: Bool = {
                    if usesBarbell { return true }
                    if ex.allowWeightToggle {
                        return workoutState.getAssistUseWeight(lift: selectedLift.rawValue, week: currentWeek)
                    }
                    return ex.defaultWeight > 0
                }()

                // Default weight:
                // 1) Barbell: prefer legacy per-lift default if present (e.g. 65 for bench),
                //    then clamp to at least the implement weight (e.g., 25 for EZ-bar).
                // 2) Non-barbell: follow toggle/default rules.
                let defaultWeight: Double = {
                    if usesBarbell {
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
                let showToggle = ex.allowWeightToggle && !usesBarbell

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
                }

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
                                // Always re-read from state; clamp to implement when barbell.
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
                            }
                        ),
                        // Plates per side when barbell + weighted
                        perSide: (usesBarbell && hasBarWeight)
                            ? calculator.plates(target: {
                                let saved = workoutState.getAssistWeight(
                                    lift: selectedLift.rawValue,
                                    week: currentWeek,
                                    set: setNum
                                ) ?? defaultWeight
                                let v = usesBarbell ? max(saved, implementW) : saved
                                return v
                              }(),
                              barWeight: implementW)
                            : [],
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
    }
}
