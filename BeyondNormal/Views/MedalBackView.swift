import SwiftUI

private struct EngravedText: View {
    let text: String
    let font: Font
    var tracking: CGFloat = 0

    var body: some View {
        ZStack {
            Text(text)
                .font(font)
                .tracking(tracking)
                .foregroundStyle(.black.opacity(0.55))
                .blur(radius: 1.2)
                .offset(x: 0.7, y: 1.0)
                .blendMode(.multiply)
                .lineLimit(1)                 // keep single line
                .minimumScaleFactor(0.70)     // shrink down to 70% before truncation
                .truncationMode(.tail)        // then add ellipsis

            Text(text)
                .font(font)
                .tracking(tracking)
                .foregroundStyle(.white.opacity(0.85))
                .blur(radius: 0.9)
                .offset(x: -0.7, y: -1.0)
                .blendMode(.screen)
                .lineLimit(1)
                .minimumScaleFactor(0.70)
                .truncationMode(.tail)

            Text(text)
                .font(font)
                .tracking(tracking)
                .foregroundStyle(.gray.opacity(0.25))
                .blendMode(.overlay)
                .opacity(0.7)
                .lineLimit(1)
                .minimumScaleFactor(0.70)
                .truncationMode(.tail)
        }
        .compositingGroup()
    }
}

struct MedalBackView: View {
    let user: String
    let line1: String
    let line2: String
    let date: Date

    var body: some View {
        // Sanitize & cap the user name (requires Core/Logic/NameRules.swift)
        let safeUser = limitedGraphemes(sanitizedDisplayName(user), max: 24).uppercased()

        ZStack {
            Image("medal_back_base")
                .resizable()
                .scaledToFit()

            VStack(spacing: 14) {
                EngravedText(
                    text: "EARNED BY \(safeUser)",
                    font: .system(size: 32, weight: .semibold, design: .rounded),
                    tracking: 2
                )
                EngravedText(
                    text: line1, // e.g., "405 LB"
                    font: .system(size: 96, weight: .black, design: .rounded)
                )
                EngravedText(
                    text: line2, // e.g., "DEADLIFT PR"
                    font: .system(size: 46, weight: .heavy, design: .rounded)
                )
                EngravedText(
                    text: date.formatted(.dateTime.month(.abbreviated).day().year()),
                    font: .system(size: 30, weight: .semibold, design: .rounded)
                )
            }
            .padding(.horizontal, 90)
            .padding(.top, 20)
        }
        .clipShape(Circle())          // trims to circular alpha
        .background(Color.clear)      // no black matte
    }
}
