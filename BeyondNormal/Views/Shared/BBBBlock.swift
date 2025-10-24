import SwiftUI

/// BBB (5×10) rendered with the exact same row UI as Assistance (AssistSetRow).
struct BBBBlock: View {
    // Inputs (same order you use at the call site)
    @Binding var selectedLift: Lift
    let currentWeek: Int
    let program: ProgramEngine
    let workoutState: WorkoutStateManager
    let calculator: PlateCalculator
    let bbbPct: Double
    let tmFor: (_ lift: Lift) -> Double
    let roundTo: Double
    let barWeightForSelectedLift: Double

    // Timer hooks (auto-start rest after each BBB set is checked done)
    let timer: TimerManager
    let timerBBBsec: Int
    let allowTimerStarts: Bool
    let armTimers: () -> Void
    let startRest: (_ seconds: Int, _ fromUser: Bool) -> Void

    var body: some View {
        if program.weekScheme(for: currentWeek).showBBB {
            VStack(alignment: .leading, spacing: 12) {
                Text("BBB — 5×10 @ \(Int(bbbPct * 100))% TM")
                    .font(.headline)

                // Stable id so plate math refreshes when lift/week change
                let refreshID = "\(selectedLift.rawValue)-\(currentWeek)"

                ForEach(1...5, id: \.self) { setNum in
                    AssistSetRow(
                        setNumber: setNum,
                        defaultWeight: defaultWeight,   // computed below via closure
                        defaultReps: 10,
                        hasBarWeight: true,
                        usesBarbell: true,
                        done: bbbDoneBinding(setNum),
                        currentWeight: Binding(
                            get: { currentBBBWeight(setNum) },
                            set: { newVal in
                                // Store nil when back to default; otherwise store explicit
                                if abs(newVal - defaultWeight) < 0.1 {
                                    workoutState.setBBBWeight(lift: liftKey, week: currentWeek, set: setNum, weight: nil)
                                } else {
                                    workoutState.setBBBWeight(lift: liftKey, week: currentWeek, set: setNum, weight: newVal)
                                }
                                // Cascade forward to remaining, not-done sets
                                cascadeBBBWeight(from: setNum, newWeight: newVal)
                            }
                        ),
                        currentReps: Binding(
                            get: { currentBBBReps(setNum) },
                            set: { newVal in
                                let clamped = max(1, min(newVal, 20))
                                if clamped == 10 {
                                    workoutState.setBBBReps(lift: liftKey, week: currentWeek, set: setNum, reps: nil)
                                } else {
                                    workoutState.setBBBReps(lift: liftKey, week: currentWeek, set: setNum, reps: clamped)
                                }
                                cascadeBBBReps(from: setNum, newReps: clamped)
                            }
                        ),
                        perSide: calculator.plates(
                            target: currentBBBWeight(setNum),
                            barWeight: barWeightForSelectedLift
                        ),
                        roundTo: roundTo,
                        onCheck: { checked in
                            // Auto-start BBB rest when a set is marked complete
                            if checked {
                                if !allowTimerStarts { armTimers() }
                                startRest(timerBBBsec, true)
                            }
                        },
                        refreshID: refreshID
                    )
                }
            }
            .cardStyle()
            .padding(.horizontal)
        }
    }

    // MARK: - Derived values / helpers

    private var liftKey: String { selectedLift.rawValue }

    private var defaultWeight: Double {
        calculator.round(tmFor(selectedLift) * bbbPct)
    }

    private func mainIndex(_ bbbSet: Int) -> Int { 3 + bbbSet } // BBB 1..5 → main 4..8

    private func bbbDoneBinding(_ setNum: Int) -> Binding<Bool> {
        Binding(
            get: { workoutState.getSetComplete(lift: liftKey, week: currentWeek, set: mainIndex(setNum)) },
            set: { newVal in
                let was = workoutState.getSetComplete(lift: liftKey, week: currentWeek, set: mainIndex(setNum))
                workoutState.setSetComplete(lift: liftKey, week: currentWeek, set: mainIndex(setNum), value: newVal)
                // Auto-start timer when flipping to done (same behavior as Assistance)
                if !was && newVal {
                    if !allowTimerStarts { armTimers() }
                    startRest(timerBBBsec, true)
                }
            }
        )
    }

    private func currentBBBWeight(_ set: Int) -> Double {
        workoutState.getBBBWeight(lift: liftKey, week: currentWeek, set: set) ?? defaultWeight
    }

    private func currentBBBReps(_ set: Int) -> Int {
        workoutState.getBBBReps(lift: liftKey, week: currentWeek, set: set) ?? 10
    }

    // Cascade forward to later NOT-DONE sets (exactly like Assistance)
    private func cascadeBBBWeight(from startSet: Int, newWeight: Double) {
        for s in startSet...5 {
            guard !workoutState.getSetComplete(lift: liftKey, week: currentWeek, set: mainIndex(s)) else { continue }
            if abs(newWeight - defaultWeight) < 0.1 {
                workoutState.setBBBWeight(lift: liftKey, week: currentWeek, set: s, weight: nil)
            } else {
                workoutState.setBBBWeight(lift: liftKey, week: currentWeek, set: s, weight: newWeight)
            }
        }
    }

    private func cascadeBBBReps(from startSet: Int, newReps: Int) {
        for s in startSet...5 {
            guard !workoutState.getSetComplete(lift: liftKey, week: currentWeek, set: mainIndex(s)) else { continue }
            if newReps == 10 {
                workoutState.setBBBReps(lift: liftKey, week: currentWeek, set: s, reps: nil)
            } else {
                workoutState.setBBBReps(lift: liftKey, week: currentWeek, set: s, reps: newReps)
            }
        }
    }
}
