//
//  TimerDock.swift
//  BeyondNormal
//
//  Created by Pat Crouse on 10/25/25.
//

import SwiftUI

struct TimerDock: View {
    let timer: TimerManager
    let regular: Int
    let bbb: Int
    @Binding var expanded: Bool
    let onStart: (Int) -> Void
    let onPause: () -> Void
    let onReset: () -> Void
    var autoCollapseAfter: Double = 1.0
    
    @Namespace private var ns
    
    var body: some View {
        // ⬇️ Only render when timer has value or is running
        if timer.isRunning || timer.remaining > 0 {
        Group {
            if expanded {
                ExpandedTimerCard(
                    timer: timer,
                    regular: regular,
                    bbb: bbb,
                    timeText: mmss(timer.remaining),   // ⬅️ format here
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
                    timeText: mmss(timer.remaining),    // ⬅️ format here
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
        .buttonStyle(.plain)
    }
}

struct ExpandedTimerCard: View {
    let timer: TimerManager
    let regular: Int
    let bbb: Int
    let timeText: String
    let onStart: (Int) -> Void
    let onPause: () -> Void
    let onReset: () -> Void
    let onCollapse: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Text(timeText)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .monospacedDigit()
                .frame(minWidth: 92, alignment: .leading)

            Spacer()

            if timer.isRunning {
                Button(action: onPause) {
                    Image(systemName: "pause.circle.fill").font(.title2)
                }
                .tint(Color.brandAccent)
            } else {
                Menu {
                    Button("Start Regular (\(regular)s)") { onStart(regular) }
                    Button("Start BBB (\(bbb)s)") { onStart(bbb) }
                } label: {
                    Image(systemName: "play.circle.fill").font(.title2)
                }
                .tint(Color.brandAccent)
            }

            Button(action: onReset) {
                Image(systemName: "gobackward").font(.title3)
            }
            .tint(.secondary)

            Button(action: onCollapse) {
                Image(systemName: "chevron.up.circle.fill").font(.title3)
            }
            .tint(.secondary)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(
            Capsule().stroke(Color.brandAccent.opacity(0.12), lineWidth: 1)
        )
    }
}
