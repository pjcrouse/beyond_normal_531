import SwiftUI

struct RestTimerCard: View {
    @ObservedObject var timer: TimerManager
    let regular: Int
    let bbb: Int

    // ✅ Inject the gated starter from ContentView
    let startRest: (Int, /*fromUser*/ Bool) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Rest Timer").font(.headline)
                Spacer()
                Text(timer.isRunning ? "Running" : "Ready")
                    .font(.caption).foregroundStyle(.secondary)
            }

            Text(timer.remaining > 0 ? mmss(timer.remaining)
                    : "Ready (\(mmss(regular)) / \(mmss(bbb)))")
                .font(.system(size: 34, weight: .bold, design: .rounded))

            HStack(spacing: 12) {
                Button { startRest(regular, true) } { Label("Start Regular", systemImage: "timer") }
                Button { startRest(bbb,     true) } { Label("Start BBB",     systemImage: "timer") }
            }
            .buttonStyle(.bordered)

            HStack(spacing: 12) {
                Button(timer.isRunning ? "Pause" : "Resume") {
                    if timer.isRunning {
                        timer.pause()
                    } else {
                        // Resume is still a *user* action — allow through the gate
                        startRest(max(timer.remaining, 1), true)
                    }
                }
                .buttonStyle(.bordered)

                Button("Reset", role: .destructive) { timer.reset() }
                    .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

private func mmss(_ s: Int) -> String {
    let m = s / 60
    let r = s % 60
    return String(format: "%d:%02d", m, r)
}
