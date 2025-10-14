import SwiftUI

struct PRsSheet: View {
    let currentCycle: Int
    let lifts: [Lift]

    // Precompute to keep the body lightweight (helps the compiler)
    private var allTimeData: [(name: String, value: Int)] {
        lifts.map { ($0.label, PRStore.shared.bestAllTime[$0.label] ?? 0) }
    }
    private var cycleData: [(name: String, value: Int)] {
        lifts.map { ($0.label, PRStore.shared.bestByCycle[PRKey(cycle: currentCycle, lift: $0.label)] ?? 0) }
    }

    var body: some View {
        NavigationStack {
            List {
                Section("All-Time Bests") {
                    ForEach(allTimeData.indices, id: \.self) { i in
                        BestRow(title: allTimeData[i].name,
                                value: allTimeData[i].value,
                                a11yPrefix: "\(allTimeData[i].name) all-time best")
                    }
                }

                Section("Cycle \(currentCycle) Bests") {
                    ForEach(cycleData.indices, id: \.self) { i in
                        BestRow(title: cycleData[i].name,
                                value: cycleData[i].value,
                                a11yPrefix: "\(cycleData[i].name) cycle best")
                    }
                }
            }
            .navigationTitle("PRs")
        }
    }
}

// Small row keeps the main view simple (faster type-checking)
private struct BestRow: View {
    let title: String
    let value: Int
    let a11yPrefix: String

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text("\(value) lb")
                .font(.headline)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(a11yPrefix) \(value) pounds")
    }
}
