import SwiftUI

/// TEMP wrapper that forwards everything to `WorkoutBlock`,
/// but lets us place main sets as a separate block.
struct MainSetsBlock: View {
    @Binding var selectedLift: Lift
    @Binding var currentWeek: Int
    @Binding var workoutNotes: String
    @FocusState.Binding var notesFocused: Bool
    @FocusState.Binding var amrapFocused: Bool

    let timer: TimerManager
    let program: ProgramEngine
    let calculator: PlateCalculator
    let barWeightForSelectedLift: Double
    let roundTo: Double
    let bbbPct: Double
    let timerRegularSec: Int
    let timerBBBsec: Int

    // ⬇️ Match WorkoutBlock’s expected return type exactly
    let est1RM: (_ lift: Lift, _ weight: Double) -> AmrapEstimate

    let setBinding: (_ idx: Int) -> Binding<Bool>
    let tmFor: (_ lift: Lift) -> Double
    @Binding var liveRepsText: String
    let workoutState: WorkoutStateManager
    let allowTimerStarts: Bool
    let armTimers: () -> Void
    let isWorkoutFinished: Bool
    let currentFormula: OneRepMaxFormula
    let availableLifts: [Lift]
    let currentCycle: Int
    let startRest: (_ seconds: Int, _ fromUser: Bool) -> Void

    var body: some View {
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
            est1RM: est1RM,                 // <- now (Lift, Double) -> AmrapEstimate
            setBinding: setBinding,
            tmFor: tmFor,
            liveRepsText: $liveRepsText,
            workoutState: workoutState,
            allowTimerStarts: allowTimerStarts,
            armTimers: armTimers,
            isWorkoutFinished: isWorkoutFinished,
            currentFormula: currentFormula,
            availableLifts: availableLifts,
            currentCycle: currentCycle,
            startRest: startRest
        )
    }
}
