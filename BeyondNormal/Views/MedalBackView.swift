import SwiftUI

// Reusable engraved text stack
private struct EngravedText: View {
    let text: String
    let font: Font
    var tracking: CGFloat = 0

    var body: some View {
        ZStack {
            // Burn / recess (darker, lower-right)
            Text(text)
                .font(font)
                .tracking(tracking)
                .foregroundStyle(.black.opacity(0.55))
                .blur(radius: 1.2)
                .offset(x: 0.7, y: 1.0)
                .blendMode(.multiply)

            // Highlight (upper-left)
            Text(text)
                .font(font)
                .tracking(tracking)
                .foregroundStyle(.white.opacity(0.85))
                .blur(radius: 0.9)
                .offset(x: -0.7, y: -1.0)
                .blendMode(.screen)

            // Subtle edge tone to keep edges crisp (optional)
            Text(text)
                .font(font)
                .tracking(tracking)
                .foregroundStyle(.gray.opacity(0.25))
                .blendMode(.overlay)
                .opacity(0.7)
        }
        .compositingGroup() // ensure blends composite against the metal
    }
}

struct MedalBackView: View {
    let user: String
    let line1: String   // e.g., "403 LB"
    let line2: String   // e.g., "DEADLIFT PR"
    let date: Date

    var body: some View {
        ZStack {
            Image("medal_back_base")
                .resizable()
                .scaledToFit()

            // Layout tuned for a 1024x1024 render, but scales nicely in the app
            VStack(spacing: 14) {
                EngravedText(
                    text: "EARNED BY \(user.uppercased())",
                    font: .system(size: 32, weight: .semibold, design: .rounded),
                    tracking: 2
                )

                EngravedText(
                    text: line1, // "403 LB"
                    font: .system(size: 96, weight: .black, design: .rounded)
                )

                EngravedText(
                    text: line2, // "DEADLIFT PR"
                    font: .system(size: 46, weight: .heavy, design: .rounded)
                )

                EngravedText(
                    text: date.formatted(.dateTime.month(.abbreviated).day().year()),
                    font: .system(size: 30, weight: .semibold, design: .rounded)
                )
            }
            .padding(.horizontal, 90) // keep text comfortably inside the rim
            .padding(.top, 20)
        }
        .background(Color.black) // overall canvas
    }
}
