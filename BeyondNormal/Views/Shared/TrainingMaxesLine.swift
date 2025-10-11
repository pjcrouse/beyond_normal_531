import SwiftUI

struct TrainingMaxesLine: View {
    let tmSquat: Double
    let tmBench: Double
    let tmDeadlift: Double
    let tmRow: Double

    var body: some View {
        VStack(spacing: 6) {
            Text("Training Maxes (lb)").font(.headline)
            Text("SQ \(fmt(tmSquat))  •  BP \(fmt(tmBench))  •  DL \(fmt(tmDeadlift))  •  ROW \(fmt(tmRow))")
                .foregroundStyle(.secondary)
        }
    }

    private func fmt(_ x: Double) -> String {
        guard x.isFinite else { return "—" }
        return x.rounded() == x ? String(format: "%.0f", x) : String(format: "%.1f", x)
    }
}
