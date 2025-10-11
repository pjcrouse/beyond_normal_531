import SwiftUI

struct PRDisclosureView: View {
    @Binding var expanded: Bool
    let tm: Double                 // training max for the selected lift
    let rounder: (Double) -> Double
    let label: String              // e.g. "Bench"

    var body: some View {
        DisclosureGroup(isExpanded: $expanded) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Week 1: 85% × 5+ → \(fmt(rounder(tm * 0.85))) lb")
                Text("Week 2: 90% × 3+ → \(fmt(rounder(tm * 0.90))) lb")
                Text("Week 3: 95% × 1+ → \(fmt(rounder(tm * 0.95))) lb")
            }
            .padding(.top, 4)
        } label: {
            Text("PR sets • \(label)")
                .font(.headline)
        }
    }

    // local tiny formatter so this file has no external helpers
    private func fmt(_ x: Double) -> String {
        x.rounded() == x ? String(format: "%.0f", x) : String(format: "%.1f", x)
    }
}
