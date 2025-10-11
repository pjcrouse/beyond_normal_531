import SwiftUI

struct SummaryCard: View {
    let date: Date
    let est1RM: Double
    let totals: (total: Int, main: Int, bbb: Int, assist: Int)

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Workout Summary").font(.headline)
                Spacer()
                Text(date, style: .date).foregroundStyle(.secondary)
            }
            if est1RM > 0 {
                Text("Estimated 1RM: \(Int(est1RM)) lb")
            } else {
                Text("Estimated 1RM: —").foregroundStyle(.secondary)
            }
            Text("Total Volume: \(totals.total) lb")
                .font(.subheadline.weight(.semibold))
                .padding(.top, 2)
            Text("Main: \(totals.main) lb  •  BBB: \(totals.bbb) lb  •  Assist: \(totals.assist) lb")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}
