import SwiftUI

struct PRDisclosureView: View {
    @Binding var expanded: Bool
    let tm: Double
    let rounder: (Double) -> Double
    let label: String
    let currentCycle: Int

    // Read current bests from PRStore
    private var cycleBest: Int {
        PRStore.shared.bestByCycle[PRKey(cycle: currentCycle, lift: label)] ?? 0
    }
    private var allTimeBest: Int {
        PRStore.shared.bestAllTime[label] ?? 0
    }

    var body: some View {
        DisclosureGroup(isExpanded: $expanded) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Training Max")
                    Spacer()
                    Text("\(Int(rounder(tm))) lb")
                        .font(.headline)
                }

                Divider().padding(.vertical, 2)

                HStack {
                    Text("Cycle PR")
                    Spacer()
                    Text(cycleBest > 0 ? "\(cycleBest) lb" : "—")
                        .font(.headline)
                        .foregroundStyle(cycleBest > 0 ? .primary : .secondary)
                }

                HStack {
                    Text("All-Time PR")
                    Spacer()
                    Text(allTimeBest > 0 ? "\(allTimeBest) lb" : "—")
                        .font(.headline)
                        .foregroundStyle(allTimeBest > 0 ? .primary : .secondary)
                }
            }
            .padding(.top, 8)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "rosette")
                Text("PRs & TM")
                    .font(.headline)
                Spacer()
                if cycleBest > 0 {
                    Tag("Cycle: \(cycleBest)")
                }
                if allTimeBest > 0 {
                    Tag("All-Time: \(allTimeBest)")
                }
            }
        }
    }
}

// Simple pill tag
private struct Tag: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text)
            .font(.caption.bold())
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(.thinMaterial, in: Capsule())
            .overlay(Capsule().stroke(Color.secondary.opacity(0.25), lineWidth: 1))
    }
}
