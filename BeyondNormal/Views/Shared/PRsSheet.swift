import SwiftUI

struct PRsSheet: View {
    let currentCycle: Int
    let lifts: [Lift]

    @StateObject private var awardStore = AwardStore()   // ← add

    // Precompute to keep the body lightweight
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

                // ---- New: Awards preview + Trophy Room entry ----
                if !awardStore.awards.isEmpty {
                    Section("Awards") {
                        // Recent medals preview (tap -> detail)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(awardStore.awards.prefix(12)) { award in
                                    NavigationLink {
                                        AwardDetailView(award: award)
                                    } label: {
                                        VStack(spacing: 6) {
                                            AwardThumb(award: award)
                                                .frame(width: 72, height: 72)
                                            Text(shortTitle(award.title))
                                                .font(.caption2)
                                                .lineLimit(1)
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 6)
                        }

                        // Full gallery
                        NavigationLink {
                            TrophyRoomView()
                        } label: {
                            Label("Open Trophy Room", systemImage: "trophy")
                                .foregroundStyle(.yellow)
                        }
                        .accessibilityLabel("Open Trophy Room")
                    }
                } else {
                    Section("Awards") {
                        Text("No medals yet. Log a PR to earn your first award!")
                            .foregroundStyle(.secondary)
                        NavigationLink("What are Awards?") {
                            TrophyRoomView()
                        }
                    }
                }
            }
            .navigationTitle("PRs & Awards")
        }
    }

    private func shortTitle(_ s: String) -> String {
        // e.g., "500 LB Deadlift PR" -> "500 LB"
        if let first = s.split(separator: " ").prefix(2).joined(separator: " ") as String? {
            return first.uppercased()
        }
        return s
    }
}

// Small thumb image view using saved PNGs
// Replace AwardThumb with a rounded-rect thumbnail
private struct AwardThumb: View {
    let award: Award
    var body: some View {
        if let img = AwardGenerator.shared.resolveImage(award.frontImagePath) {
            img.resizable()
                .scaledToFit()
                .padding(6)
                .background(.black, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(.white.opacity(0.08), lineWidth: 1))
                .shadow(color: .black.opacity(0.4), radius: 3, y: 2)
        } else {
            RoundedRectangle(cornerRadius: 14).fill(Color.gray.opacity(0.25))
        }
    }
}

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
