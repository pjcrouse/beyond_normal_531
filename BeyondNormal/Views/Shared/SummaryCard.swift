import SwiftUI

/// Reusable workout summary card.
/// - Backward compatible with your old initializer:
///   SummaryCard(date: .now, est1RM: x, totals: (total, main, bbb, assist))
struct SummaryCard: View {
    // MARK: Inputs
    let date: Date
    let est1RM: Double

    /// Core volumes; `joker` is optional so older calls still work.
    struct Totals {
        let total: Int
        let main: Int
        let bbb: Int
        let assist: Int
        let joker: Int?    // nil means "not tracked / not shown"
    }
    let totals: Totals

    /// Optional extra details
    let focusLift: String?     // e.g. "Bench"
    let prAchieved: Bool       // shows trophy if true

    // MARK: - Convenience init (back-compat)
    init(
        date: Date,
        est1RM: Double,
        totals: (total: Int, main: Int, bbb: Int, assist: Int),
        focusLift: String? = nil,
        joker: Int? = nil,
        prAchieved: Bool = false
    ) {
        self.date = date
        self.est1RM = est1RM
        self.totals = Totals(
            total: totals.total,
            main: totals.main,
            bbb: totals.bbb,
            assist: totals.assist,
            joker: joker
        )
        self.focusLift = focusLift
        self.prAchieved = prAchieved
    }

    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            headerRow

            if est1RM > 0 {
                Text("Estimated 1RM: \(Int(est1RM)) lb")
                    .font(.subheadline.weight(.semibold))
            } else {
                Text("Estimated 1RM: —")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Text("Total Volume: \(formatted(totals.total)) lb")
                .font(.subheadline.weight(.semibold))
                .padding(.top, 2)

            // Breakdown lines (Joker row only appears if > 0, so no blank gap)
            VStack(alignment: .leading, spacing: 4) {
                Text("Main: \(formatted(totals.main)) lb")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("BBB: \(formatted(totals.bbb)) lb")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("Assist: \(formatted(totals.assist)) lb")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let jk = totals.joker, jk > 0 {
                    Text("Joker: \(formatted(jk)) lb")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        // no internal card background; you’re already calling `.cardStyle()` at the call site
    }

    // MARK: - Pieces

    private var headerRow: some View {
        HStack(spacing: 8) {
            Text("Workout Summary")
                .font(.headline)

            if let lift = focusLift, !lift.isEmpty {
                Text("• \(lift)")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }

            if prAchieved {
                Image(systemName: "trophy.fill")
                    .foregroundStyle(Color.brandAccent)
                    .accessibilityLabel("PR achieved")
            }

            Spacer()

            // MM/DD/YY HH:MM (24h, no AM/PM)
            Text(
                date.formatted(
                    .dateTime
                        .month(.twoDigits)
                        .day(.twoDigits)
                        .year(.twoDigits)
                        .hour(.twoDigits(amPM: .omitted))
                        .minute(.twoDigits)
                )
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
    }

    // MARK: - Small helpers
    private func formatted(_ n: Int) -> String {
        n.formatted(.number)
    }
}
