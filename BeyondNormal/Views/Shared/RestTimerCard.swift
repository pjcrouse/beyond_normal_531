import SwiftUI

struct RestTimerCard: View {
    @ObservedObject var timer: TimerManager
    let regular: Int
    let bbb: Int

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
                Button { timer.start(seconds: regular) } label: { Label("Start Regular", systemImage: "timer") }
                Button { timer.start(seconds: bbb) } label: { Label("Start BBB", systemImage: "timer") }
            }
            .buttonStyle(.bordered)

            HStack(spacing: 12) {
                Button(timer.isRunning ? "Pause" : "Resume") {
                    if timer.isRunning { timer.pause() } else { timer.start(seconds: max(timer.remaining, 1)) }
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
