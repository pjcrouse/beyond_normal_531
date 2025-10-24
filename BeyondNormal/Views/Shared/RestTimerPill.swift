//
//  RestTimerPill.swift
//  BeyondNormal
//
//  Created by Pat Crouse on 10/24/25.
//

import SwiftUI

struct RestTimerPill: View {
    @ObservedObject var timer: TimerManager
    let regular: Int
    let bbb: Int
    let onStart: (Int) -> Void
    let onPause: () -> Void
    let onReset: () -> Void

    @State private var expanded = false

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "timer")
                .imageScale(.medium)

            if expanded {
                Text(display).monospacedDigit().font(.headline)
                Spacer(minLength: 4)
                Button("Start \(mmss(regular))") { onStart(regular) }.buttonStyle(.bordered)
                Button("BBB \(mmss(bbb))") { onStart(bbb) }.buttonStyle(.bordered)
                Button(timer.isRunning ? "Pause" : "Resume") {
                    timer.isRunning ? onPause() : onStart(timer.remaining)
                }.buttonStyle(.bordered)
                Button("Reset", role: .destructive) { onReset() }.buttonStyle(.bordered)
            } else {
                Text(display).monospacedDigit().font(.subheadline.weight(.semibold))
            }
        }
        .padding(.vertical, 8).padding(.horizontal, 12)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().strokeBorder(Color.secondary.opacity(0.15), lineWidth: 1))
        .onTapGesture { withAnimation(.spring()) { expanded.toggle() } }
        .onChange(of: timer.isRunning) { _, running in
            if running {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    withAnimation(.spring()) { expanded = false }
                }
            }
        }
    }

    private var display: String { timer.isRunning ? "Rest \(mmss(timer.remaining))" : "Ready" }
    private func mmss(_ s: Int) -> String { String(format: "%d:%02d", s/60, s%60) }
}
