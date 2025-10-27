//
//  TimerDock.swift
//  BeyondNormal
//
//  Created by Pat Crouse on 10/25/25.
//

import SwiftUI

struct TimerDock: View {
    @ObservedObject var timer: TimerManager   // reactive so pill updates live
    let regular: Int
    let bbb: Int
    @Binding var expanded: Bool
    let onStart: (Int) -> Void
    let onPause: () -> Void
    let onReset: () -> Void
    var autoCollapseAfter: Double = 1.0

    @Namespace private var ns

    var body: some View {
        // Only render when timer has value or is running
        if timer.isRunning || timer.remaining > 0 {
            Group {
                if expanded {
                    ExpandedTimerCard(
                        timer: timer,
                        regular: regular,
                        bbb: bbb,
                        timeText: mmss(timer.remaining),
                        onStart: { secs in
                            onStart(secs)
                            collapseSoon()
                        },
                        onPause: onPause,
                        onReset: onReset,
                        onCollapse: { expanded = false }
                    )
                    .matchedGeometryEffect(id: "timerDock", in: ns)
                    .transition(.move(edge: .top).combined(with: .opacity))
                } else {
                    CollapsedTimerBadge(
                        timeText: mmss(timer.remaining),
                        isRunning: timer.isRunning,
                        onTap: { expanded = true }
                    )
                    .matchedGeometryEffect(id: "timerDock", in: ns)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.9), value: expanded)
            .onChange(of: timer.isRunning) { _, isRunning in
                if isRunning, expanded { collapseSoon() }
            }
        }
    }

    private func collapseSoon() {
        DispatchQueue.main.asyncAfter(deadline: .now() + autoCollapseAfter) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                expanded = false
            }
        }
    }

    // Simple mm:ss formatter
    private func mmss(_ secs: Int) -> String {
        let s = max(0, secs)
        let m = s / 60
        let r = s % 60
        return String(format: "%02d:%02d", m, r)
    }
}

struct CollapsedTimerBadge: View {
    let timeText: String
    let isRunning: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Image(systemName: isRunning ? "timer.circle.fill" : "timer")
                Text(timeText)
                    .monospacedDigit()
                    .font(.headline)
            }
            .foregroundStyle(Color.white)
            .padding(.vertical, 8)
            .padding(.horizontal, 14)
            .background(Color.brandAccent, in: Capsule())
            .shadow(color: Color.brandAccent.opacity(0.25), radius: 8, y: 4)
        }
        .accessibilityLabel(isRunning ? "Rest timer running" : "Rest timer")
        .accessibilityValue(timeText)
        .buttonStyle(.plain)
    }
}

struct ExpandedTimerCard: View {
    @EnvironmentObject private var settings: ProgramSettings
    @ObservedObject var timer: TimerManager
    let regular: Int
    let bbb: Int
    let timeText: String
    let onStart: (Int) -> Void
    let onPause: () -> Void
    let onReset: () -> Void
    let onCollapse: () -> Void

    // Nudge and floor (1 minute)
    private let nudgeStep = 60
    private let safeFloor = 60

    var body: some View {
        HStack(spacing: 12) {
            // −60s (temporary adjust)
            Button {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                    if timer.remaining > safeFloor {
                        timer.adjust(by: -nudgeStep)
                    }
                }
            } label: {
                Image(systemName: "minus.circle.fill")
                    .font(.title2)
                    .opacity(canMinus ? 1 : 0.35)
            }
            .buttonStyle(.plain)
            .disabled(!canMinus)
            .contextMenu {
                Button("Set as new default") {
                    timer.persistCurrentAsDefault(settings)
                }
            }
            .accessibilityLabel("Decrease rest by 60 seconds")
            .accessibilityHint("Long-press to set as new default")

            // Time readout
            Text(timeText)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .monospacedDigit()
                .frame(minWidth: 92, alignment: .center)
                .accessibilityLabel("Remaining rest time")
                .accessibilityValue(timeText)

            // +60s (temporary adjust)
            Button {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                    timer.adjust(by: +nudgeStep)
                }
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
            }
            .buttonStyle(.plain)
            .contextMenu {
                Button("Set as new default") {
                    timer.persistCurrentAsDefault(settings)
                }
            }
            .accessibilityLabel("Increase rest by 60 seconds")
            .accessibilityHint("Long-press to set as new default")

            Spacer()

            if timer.isRunning {
                Button(action: onPause) {
                    Image(systemName: "pause.circle.fill").font(.title2)
                }
                .tint(Color.brandAccent)
                .accessibilityLabel("Pause timer")
            } else {
                Menu {
                    Button("Start Regular (\(mmss(regular)))") { onStart(regular) }
                    Button("Start BBB (\(mmss(bbb)))")       { onStart(bbb) }
                } label: {
                    Image(systemName: "play.circle.fill").font(.title2)
                }
                .tint(Color.brandAccent)
                .accessibilityLabel("Start timer")
            }

            Button(action: onReset) {
                Image(systemName: "gobackward").font(.title3)
            }
            .tint(.secondary)
            .accessibilityLabel("Reset timer")

            Button(action: onCollapse) {
                Image(systemName: "chevron.up.circle.fill").font(.title3)
            }
            .tint(.secondary)
            .accessibilityLabel("Collapse timer")
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(
            Capsule().stroke(Color.brandAccent.opacity(0.12), lineWidth: 1)
        )
    }

    private var canMinus: Bool { timer.remaining > safeFloor }

    private func mmss(_ secs: Int) -> String {
        let s = max(0, secs), m = s / 60, r = s % 60
        return String(format: "%02d:%02d", m, r)
    }
}
