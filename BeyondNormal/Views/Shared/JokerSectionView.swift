//  JokerSectionView.swift
//  BeyondNormal

import SwiftUI
// If you have separate targets/modules, uncomment the next line:
// import CoreModels

struct JokerSectionView: View {
    let jokerSets: [SetPrescription]     // ← use the shared model
    let showFeedback: Bool
    let onFire: () -> Void
    let onDumpster: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "flame.fill")
                Text("Joker Sets")
                    .font(.headline)
                Spacer()
            }
            .foregroundStyle(Color.brandAccent)

            ForEach(jokerSets) { js in
                // Precompute strings to help the type-checker
                let pctText = "\(Int(js.percentOfTM * 100))% TM"
                let repWeightText = "\(js.reps) × \(Int(js.weight))"

                HStack {
                    Text(pctText)
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Text(repWeightText)
                        .monospacedDigit()
                }
                .padding(.vertical, 4)
            }

            if showFeedback {
                Divider().opacity(0.2)
                HStack(spacing: 14) {
                    Text("How did that feel?")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button(action: onDumpster) { Text("🗑️") }.buttonStyle(.plain)
                    Button(action: onFire)     { Text("🔥")   }.buttonStyle(.plain)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
