import SwiftUI

struct FormulaTag: View {
    let formula: OneRepMaxFormula

    var body: some View {
        Text(formula.displayName)
            .font(.caption.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.thinMaterial, in: Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.secondary.opacity(0.25), lineWidth: 1)
            )
            .accessibilityLabel("Using \(formula.displayName) formula")
            .help(formula.description)  // nice on long-press / pointer
    }
}

#Preview {
    ZStack { Color(.systemBackground).ignoresSafeArea()
        FormulaTag(formula: .epley)
            .padding()
    }
}
