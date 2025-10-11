import SwiftUI

struct PRSetsDisclosure: View {
    @Binding var isExpanded: Bool
    let liftLabel: String
    let week1W: Double
    let week2W: Double
    let week3W: Double

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Week 1: 85% × 5+ → \(fmt(week1W)) lb")
                Text("Week 2: 90% × 3+ → \(fmt(week2W)) lb")
                Text("Week 3: 95% × 1+ → \(fmt(week3W)) lb")
            }
            .padding(.top, 4)
        } label: {
            Text("PR sets • \(liftLabel)")
                .font(.headline)
        }
    }

    private func fmt(_ x: Double) -> String {
        x.rounded() == x ? String(format: "%.0f", x) : String(format: "%.1f", x)
    }
}
