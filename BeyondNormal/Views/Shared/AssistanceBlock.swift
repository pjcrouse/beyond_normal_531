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

    /// Closure to map the selected main lift to the chosen assistance exercise
    let assistanceFor: (Lift) -> AssistanceExercise

    /// Binding provider for assist set completion (sets 1...3)
    let assistSetBinding: (Int) -> Binding<Bool>

    var body: some View {
        let scheme = program.weekScheme(for: currentWeek)
        let ex = assistanceFor(selectedLift)

        // Assistance that should render barbell plates
        let barAssistanceIDs: Set<String> = ["front_squat", "paused_squat", "close_grip"]
        let usesBarbell = barAssistanceIDs.contains(ex.id)
        let implementW = implements.weight(for: ex.id)

        return Group {
            if scheme.showBBB {
                Divider().padding(.vertical, 6)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Assistance — \(ex.name)")
                        .font(.headline)

                    // Only show toggle if the exercise allows it
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

                // Whether we’re using any load at all for this assistance block
                let useWeight =
                    ex.defaultWeight > 0 ||
                    (ex.allowWeightToggle && workoutState.getAssistUseWeight(lift: selectedLift.rawValue, week: currentWeek))

                // The default assistance weight considering the toggle logic
                let defaultWeight =
                    ex.defaultWeight > 0
                    ? ex.defaultWeight
                    : (ex.allowWeightToggle && workoutState.getAssistUseWeight(lift: selectedLift.rawValue, week: currentWeek)
                       ? ex.toggledWeight
                       : 0)

                ForEach(1...3, id: \.self) { setNum in
                    let currentW = workoutState.getAssistWeight(
                        lift: selectedLift.rawValue,
                        week: currentWeek,
                        set: setNum
                    ) ?? defaultWeight

                    AssistSetRow(
                        setNumber: setNum,
                        defaultWeight: defaultWeight,
                        defaultReps: ex.defaultReps,
                        hasBarWeight: useWeight,
                        usesBarbell: usesBarbell,
                        done: assistSetBinding(setNum),
                        currentWeight: Binding(
                            get: {
                                workoutState.getAssistWeight(
                                    lift: selectedLift.rawValue,
                                    week: currentWeek,
                                    set: setNum
                                ) ?? defaultWeight
                            },
                            set: { newVal in
                                if abs(newVal - defaultWeight) < 0.1 {
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
                                        weight: newVal
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
}
