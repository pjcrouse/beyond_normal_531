import SwiftUI

struct WarmupGuideView: View {
    let lift: Lift
    let targetWeight: Double     // first main working-set weight for today
    let barWeight: Double
    let roundTo: Double
    let calculator: PlateCalculator

    var body: some View {
        List {
            Section("Start Here") {
                VStack(alignment: .leading, spacing: 6) {
                    Text(suggestedMovement(for: lift))
                        .font(.body)
                    Text("Keep it truly easy—just enough to raise heart rate and loosen the pattern.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            Section {
                headerRow
                ForEach(warmupSteps) { step in
                    WarmupSetRow(
                        weight: step.weight,
                        reps: step.reps,
                        perSide: perSide(for: step.weight)
                    )
                }
                targetPreviewRow
            } header: {
                Text("Ramped Warmup to First Set")
            } footer: {
                Text("Finish the last single with crisp speed. Rest ~2–3 minutes and begin your first set.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Warmup — \(lift.label)")
    }

    private var warmupSteps: [WarmupStep] {
        buildWarmupPlan(target: targetWeight, bar: barWeight, roundTo: roundTo)
    }

    private func perSide(for total: Double) -> [Double] {
        calculator.plates(target: total, barWeight: barWeight)
    }

    @ViewBuilder
    private var headerRow: some View {
        HStack {
            Text("Today’s first set:")
            Spacer()
            Text("\(Int(targetWeight)) lb").font(.headline)
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var targetPreviewRow: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Then begin:")
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(targetWeight)) lb × first set")
                    .font(.headline)
                let ps = perSide(for: targetWeight)
                if !ps.isEmpty {
                    Text("Per side: " + LoadFormat.plateList(ps))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

private struct WarmupSetRow: View {
    let weight: Double
    let reps: Int
    let perSide: [Double]

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("\(reps) reps")
            Spacer(minLength: 12)
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(weight)) lb").font(.headline)
                if !perSide.isEmpty {
                    Text("Per side: " + LoadFormat.plateList(perSide))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 2)
    }
}
