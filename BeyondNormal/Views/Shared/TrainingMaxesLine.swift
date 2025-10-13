import SwiftUI

struct TrainingMaxesLine: View {
    let tmSquat: Double
    let tmBench: Double
    let tmDeadlift: Double
    let tmRow: Double
    let tmPress: Double?
    let activeLifts: [Lift]

    var body: some View {
        // Build items in the order of activeLifts
        let items: [(String, Int)] = activeLifts.compactMap { lift in
            switch lift {
            case .squat:   return ("SQ", Int(tmSquat))
            case .bench:   return ("BP", Int(tmBench))
            case .deadlift:return ("DL", Int(tmDeadlift))
            case .row:     return ("RW", Int(tmRow))
            case .press:
                if let p = tmPress { return ("PR", Int(p)) }
                else { return ("PR", Int(tmBench)) } // graceful fallback if somehow nil
            }
        }

        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    HStack(spacing: 6) {
                        Text(item.0)
                            .font(.caption2.weight(.bold))
                            .padding(.horizontal, 6).padding(.vertical, 4)
                            .background(.thinMaterial, in: Capsule())
                            .overlay(Capsule().stroke(Color.secondary.opacity(0.25), lineWidth: 1))
                        Text("\(item.1) lb")
                            .font(.subheadline.monospacedDigit())
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding(.horizontal)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Training maxes")
    }
}
