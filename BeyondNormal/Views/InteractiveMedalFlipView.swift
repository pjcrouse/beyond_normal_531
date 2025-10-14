import SwiftUI

struct InteractiveMedalFlipView: View {
    let award: Award

    @State private var angle: CGFloat = 0
    @GestureState private var dragOffset: CGFloat = 0
    @State private var baseAngle: CGFloat = 0
    @State private var isFlipped: Bool = false

    private let pxToDeg: CGFloat = 0.5
    private let perspective: CGFloat = 0.6
    private let completeThreshold: CGFloat = 0.45

    var body: some View {
        ZStack {
            // FRONT
            layerImage(front: true)
                .opacity(frontOpacity)
                .rotation3DEffect(.degrees(Double(angle)),
                                  axis: (x: 0.1, y: 1, z: 0),
                                  perspective: perspective)

            // BACK
            layerImage(front: false)
                .opacity(backOpacity)
                .rotation3DEffect(.degrees(Double(angle - 180)),
                                  axis: (x: 0.1, y: 1, z: 0),
                                  perspective: perspective)
        }
        .contentShape(Rectangle())
        .gesture(dragGesture)
        .onChange(of: isFlipped) { flipped in
            baseAngle = flipped ? 180 : 0
            angle = baseAngle
        }
        .onAppear {
            baseAngle = isFlipped ? 180 : 0
            angle = baseAngle
        }
        .animation(.interactiveSpring(response: 0.45, dampingFraction: 0.85), value: angle)
        .shadow(color: .black.opacity(0.35), radius: 18, x: 0, y: 10)
        .aspectRatio(1, contentMode: .fit)
    }
    
    private var shimmerIntensity: Double {
        // Peaks at ~90°, fades out on front/back
        let normalized = sin(Double(angle) * .pi / 180.0)
        // narrow the peak window to keep it subtle
        return abs(normalized) > 0.8 ? abs(normalized) * 0.5 : 0
    }

    // MARK: - Gesture

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .updating($dragOffset) { value, state, _ in
                state = value.translation.width
                let live = baseAngle + (value.translation.width * pxToDeg)
                angle = clamp(live, 0, 180)
            }
            .onEnded { value in
                let delta = value.translation.width * pxToDeg
                let target = snapTarget(progress: progress(at: baseAngle + delta))
                isFlipped = (target >= 0.5)
                angle = isFlipped ? 180 : 0
                baseAngle = angle
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            }
    }

    // MARK: - Layers

    private func layerImage(front: Bool) -> some View {
        Group {
            if let img = AwardGenerator.shared.resolveImage(front ? award.frontImagePath : award.backImagePath) {
                img
                    .resizable()
                    .scaledToFit()
                    .clipShape(Circle())
            } else {
                Circle().fill(Color.gray.opacity(0.2))
                    .overlay(Text(front ? "Front missing" : "Back missing").font(.caption))
            }
        }
    }

    // MARK: - Helpers

    private var frontOpacity: Double {
        Double(clamp(1 - (angle / 90), 0, 1))
    }

    private var backOpacity: Double {
        Double(clamp((angle - 90) / 90, 0, 1))
    }

    private func progress(at degrees: CGFloat) -> CGFloat {
        clamp(degrees / 180, 0, 1)
    }

    private func snapTarget(progress p: CGFloat) -> CGFloat {
        p >= completeThreshold ? 1.0 : 0.0
    }

    private func clamp(_ x: CGFloat, _ a: CGFloat, _ b: CGFloat) -> CGFloat {
        min(max(x, a), b)
    }
}
