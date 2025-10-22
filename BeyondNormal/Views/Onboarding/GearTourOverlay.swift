import SwiftUI

struct GearTourOverlay: View {
    @EnvironmentObject private var tour: TourController
    @State private var manualOffset: CGSize = .zero

    let targets: [TourTargetID: Anchor<CGRect>]
    let proxy: GeometryProxy

    private let cornerRadius: CGFloat = 14
    private let pad: CGFloat = 8

    var body: some View {
        let dimAmount: Double = (tour.currentTarget == .helpIcon) ? 0.92 : 0.80
        
        // Show only when active and we have an anchor for the current target
        guard tour.isActive,
              let target = tour.currentTarget,
              let a = targets[target] else {
            return AnyView(EmptyView())
        }

        let rect = proxy[a].insetBy(dx: -pad, dy: -pad)

        return AnyView(
            ZStack {
                // Dim everything except the highlighted hole
                Color.black.opacity(dimAmount)
                    .ignoresSafeArea()
                    .mask(
                        Canvas { ctx, size in
                            var path = Path(CGRect(origin: .zero, size: size))
                            let hole = RoundedRectangle(cornerRadius: cornerRadius).path(in: rect)
                            path.addPath(hole)
                            ctx.fill(path, with: .color(.black), style: FillStyle(eoFill: true))
                        }
                    )
                    .allowsHitTesting(false) // let taps go through to real controls

                // Card content
                VStack(spacing: 8) {
                    Text(tour.titleForCurrent)
                        .font(.headline).bold()

                    Text(tour.messageForCurrent)
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 280)

                    // CTA shown ONLY on the Training Maxes step
                    if tour.currentTarget == .trainingMaxes {
                        Button {
                            tour.go(to: .helpIcon)
                        } label: {
                            Text("Next: Open User Guide")
                                .font(.headline)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(.thinMaterial, in: Capsule())
                        }
                        .padding(.top, 6)
                    }

                    Button("Skip") { tour.complete() }
                        .buttonStyle(.bordered)
                        .padding(.top, 2)
                }
                .padding(14)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(.white.opacity(0.2)))
                .position(cardPosition(around: rect, in: proxy.size))
                .offset(manualOffset)
                .gesture(
                    DragGesture()
                        .onChanged { manualOffset = $0.translation }
                        .onEnded { _ in manualOffset = .zero }
                )
            }
            .animation(.easeInOut(duration: 0.30), value: rect)
        )
    }

    // MARK: - Card placement relative to highlighted rect

    private func cardPosition(around rect: CGRect, in size: CGSize) -> CGPoint {
        // Placement preferences per step
        let forceBelow = (tour.currentTarget == .displayName || tour.currentTarget == .helpIcon)
        let forceAbove = (tour.currentTarget == .trainingMaxes)

        let verticalPad: CGFloat = 110
        let minTop: CGFloat = 110
        let minBottom: CGFloat = 140

        let yAbove = max(rect.minY - verticalPad, minTop)
        let yBelow = min(rect.maxY + verticalPad, size.height - minBottom)

        let chooseAbove: Bool
        if forceAbove { chooseAbove = true }
        else if forceBelow { chooseAbove = false }
        else {
            // default: choose side with more room
            let roomAbove = rect.minY
            let roomBelow = size.height - rect.maxY
            chooseAbove = roomAbove > roomBelow
        }

        let y = chooseAbove ? yAbove : yBelow
        let minX: CGFloat = 200
        let maxX: CGFloat = size.width - 200
        let x = min(max(rect.midX, minX), maxX)
        return CGPoint(x: x, y: y)
    }
}
