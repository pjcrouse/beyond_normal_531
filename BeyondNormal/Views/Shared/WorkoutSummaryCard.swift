import SwiftUI

struct WorkoutSummaryCard: View {
    struct Metrics {
        let date: Date
        let est1RM: Double
        let total: Int
        let main: Int
        let bbb: Int
        let assist: Int
    }

    let metrics: Metrics

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Workout Summary").font(.headline)
                Spacer()
                Text(metrics.date, style: .date).foregroundStyle(.secondary)
            }

            if metrics.est1RM > 0 {
                Text("Estimated 1RM: \(Int(metrics.est1RM)) lb")
            } else {
                Text("Estimated 1RM: —").foregroundStyle(.secondary)
            }

            Text("Total Volume: \(metrics.total) lb")
                .font(.subheadline.weight(.semibold))
                .padding(.top, 2)

            Text("Main: \(metrics.main) lb  •  BBB: \(metrics.bbb) lb  •  Assist: \(metrics.assist) lb")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}
