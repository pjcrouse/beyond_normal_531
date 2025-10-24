import SwiftUI

struct QuickTargetHeader: View {
    let cycle: Int
    let week: Int
    let liftLabel: String
    let topLine: String
    let topWeight: Double

    var body: some View {
        VStack(spacing: 4) {
            Text("Cycle \(cycle) • Week \(week) • \(liftLabel)")
                .font(.headline)
            Text("\(topLine) → \(fmt(topWeight)) lb")
                .font(.title3.weight(.bold))
                .foregroundColor(.brandAccent)
        }
        .padding(.top, 6)
    }

    private func fmt(_ x: Double) -> String {
        x.rounded() == x ? String(format: "%.0f", x) : String(format: "%.1f", x)
    }
}
