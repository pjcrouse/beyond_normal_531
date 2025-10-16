import SwiftUI
import SceneKit
import UIKit

struct Medal3DView: UIViewRepresentable {
    let award: Award
    var thickness: CGFloat = 0.08
    var radius: CGFloat = 1.0

    func makeUIView(context: Context) -> SCNView {
        let view = SCNView()
        view.backgroundColor = .clear
        view.scene = SCNScene()
        view.antialiasingMode = .multisampling4X
        view.isPlaying = true
        view.isUserInteractionEnabled = true
        view.autoenablesDefaultLighting = false
        view.allowsCameraControl = false // keep gestures ours, not SceneKit's

        // Camera
        let camera = SCNCamera()
        camera.fieldOfView = 40
        let camNode = SCNNode()
        camNode.camera = camera
        camNode.position = SCNVector3(0, 0, 3.0)
        view.scene?.rootNode.addChildNode(camNode)

        // Lights
        let key = SCNLight(); key.type = .omni; key.intensity = 900
        let keyNode = SCNNode(); keyNode.light = key; keyNode.position = SCNVector3(2, 3, 5)
        view.scene?.rootNode.addChildNode(keyNode)

        let fill = SCNLight(); fill.type = .omni; fill.intensity = 400
        let fillNode = SCNNode(); fillNode.light = fill; fillNode.position = SCNVector3(-3, -1, 4)
        view.scene?.rootNode.addChildNode(fillNode)

        let amb = SCNLight(); amb.type = .ambient; amb.intensity = 150
        let ambNode = SCNNode(); ambNode.light = amb
        view.scene?.rootNode.addChildNode(ambNode)

        // --- Medal hierarchy ---
        // Parent "spinner" rotates around Y from the gesture.
        let spinner = SCNNode()

        // Child "pose" holds the fixed facing: X=+90°, Z=−90°
        let pose = buildMedalNode()
        pose.eulerAngles = SCNVector3(Float.pi/2, 0, -Float.pi/2)

        spinner.addChildNode(pose)
        view.scene?.rootNode.addChildNode(spinner)

        // Coordinator hooks
        context.coordinator.spinner = spinner
        context.coordinator.yAngle = 0 // spinner starts at 0 (child provides fixed tilt)

        // Gesture
        let pan = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        pan.maximumNumberOfTouches = 1
        view.addGestureRecognizer(pan)

        return view
    }

    func updateUIView(_ view: SCNView, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    private func buildMedalNode() -> SCNNode {
        let cyl = SCNCylinder(radius: radius, height: thickness)
        cyl.radialSegmentCount = 96

        let side = SCNMaterial()
        side.diffuse.contents   = UIColor(white: 0.18, alpha: 1)
        side.metalness.contents = 1.0
        side.roughness.contents = 0.35
        side.lightingModel = .physicallyBased

        // FRONT FACE
        let front = SCNMaterial()
        front.diffuse.contents   = AwardGenerator.shared.resolveUIImage(award.frontImagePath)
        front.metalness.contents = 0.9
        front.roughness.contents = 0.4
        front.isDoubleSided = false
        front.lightingModel = .physicallyBased
        // keep the normal vertical flip for UIKit images
        front.diffuse.contentsTransform = SCNMatrix4MakeScale(1, -1, 1)
        front.diffuse.wrapT = .repeat

        // BACK FACE
        let back = SCNMaterial()
        back.diffuse.contents   = AwardGenerator.shared.resolveUIImage(award.backImagePath)
        back.metalness.contents = 0.9
        back.roughness.contents = 0.4
        back.isDoubleSided = false
        back.lightingModel = .physicallyBased

        // rotate 90° CW around the UV center: T(0.5,0.5) * R(-90°) * T(-0.5,-0.5)
        let Tcenter    = SCNMatrix4MakeTranslation(0.5, 0.5, 0)
        let Tuncenter  = SCNMatrix4MakeTranslation(-0.5, -0.5, 0)
        let rotateCW90 = SCNMatrix4MakeRotation(-Float.pi / 2, 0, 0, 1)
        let swapUV_CW  = SCNMatrix4Mult(SCNMatrix4Mult(Tcenter, rotateCW90), Tuncenter)

        // optional: if the text is mirrored after the swap, flip U (horizontal)
        // comment this next line out if it isn’t mirrored on your device
        let fixMirrorU = SCNMatrix4MakeScale(-1, 1, 1)
        let swapThenFix = SCNMatrix4Mult(swapUV_CW, fixMirrorU)

        // EXTRA: final 90° screen-space rotation about the UV center
        let extraCW90  = SCNMatrix4Mult(SCNMatrix4MakeTranslation(0.5, 0.5, 0),
                                        SCNMatrix4Mult(SCNMatrix4MakeRotation(-.pi/2, 0, 0, 1),
                                                       SCNMatrix4MakeTranslation(-0.5, -0.5, 0)))

        // apply it after the existing swap+mirror
        let finalBackXform = SCNMatrix4Mult(swapThenFix, extraCW90)
        back.diffuse.contentsTransform = finalBackXform

        back.diffuse.wrapS = .repeat
        back.diffuse.wrapT = .repeat

        cyl.materials = [side, front, back]
        return SCNNode(geometry: cyl)
    }

    // MARK: - Coordinator (Y-only spin on parent; fixed pose on child) with inertia + velocity flips
    final class Coordinator: NSObject {
        var parent: Medal3DView
        weak var spinner: SCNNode?

        // Continuous Y angle for 360° spinning (radians, unbounded; normalized when used)
        var yAngle: Float = 0

        // Gesture state
        private var lastX: CGFloat = 0

        // ====== Tuning ======
        // Drag sensitivity (px -> rad) while finger is down
        private let pxToRad: CGFloat = 0.01

        // Deadzone to ignore tiny jitter
        private let jitterDeadzone: CGFloat = 1.2

        // Flick physics
        // Converts pan velocity (px/s) to angular velocity (rad/s) at release
        private let velPxPerSec_toRadPerSec: CGFloat = 0.0075

        // Angular deceleration (rad/s^2). Higher = stops sooner (less coasting).
        private let angularDecel: CGFloat = 20.0

        // Cap the starting angular velocity (safety & feel)
        private let maxOmega: CGFloat = 18.0  // rad/s (~3 rev/s)

        // Minimum velocity to treat as a flick. Below this -> midpoint snap (single flip or snap back).
        private let minFlickOmega: CGFloat = 0.8 // rad/s

        // Optional: haptic feedback on final settle
        private let hapticsEnabled = true

        init(_ parent: Medal3DView) { self.parent = parent }

        @objc func handlePan(_ pan: UIPanGestureRecognizer) {
            guard let node = spinner, let view = pan.view else { return }
            let p = pan.translation(in: view)

            switch pan.state {
            case .began:
                lastX = p.x
                // Cancel any running spin so user takes control immediately
                node.removeAllActions()

            case .changed:
                var dx = p.x - lastX
                if abs(dx) < jitterDeadzone { dx = 0 }
                lastX = p.x

                yAngle += Float(dx * pxToRad)
                yAngle = normalize2Pi(yAngle)
                node.eulerAngles = SCNVector3(0, yAngle, 0)

            case .ended, .cancelled:
                // --- Inertial continuation using flick velocity ---
                let vx = pan.velocity(in: view).x  // px/s
                var omega0 = vx * velPxPerSec_toRadPerSec  // rad/s
                omega0 = clamp(omega0, -maxOmega, maxOmega)

                if abs(omega0) < minFlickOmega {
                    // Too weak to coast: do a simple midpoint snap (binary, no hysteresis)
                    let target = snapTargetMidpoint(currentAngle: yAngle)
                    animateTo(node: node, targetAngle: target, duration: 0.28, shortestArc: true)
                    return
                }

                // Physics: coast with constant decel to rest
                // Time to stop: t = |ω0| / α
                let t = abs(omega0) / angularDecel

                // Angular travel until rest: Δθ = ω0^2 / (2α)
                let travel = (omega0 * omega0) / (2.0 * angularDecel) // positive
                let signedTravel = (omega0 >= 0 ? travel : -travel)

                // Proposed final angle before snapping
                let proposed = Float(CGFloat(yAngle) + signedTravel)

                // Snap to nearest multiple of π so we land exactly on a face (enables multi-flip)
                let snapped = nearestMultipleOfPi(proposed)

                // Animate to snapped with duration t; preserve direction (no shortest-arc hop)
                animateTo(node: node, targetAngle: snapped, duration: t, shortestArc: false)

            default:
                break
            }
        }

        // MARK: - Animation helper

        private func animateTo(node: SCNNode, targetAngle: Float, duration: CGFloat, shortestArc: Bool) {
            let action = SCNAction.rotateTo(
                x: 0,
                y: CGFloat(targetAngle),
                z: 0,
                duration: TimeInterval(max(0.12, duration)),
                usesShortestUnitArc: shortestArc == true
            )
            action.timingMode = .easeOut
            node.runAction(action) { [weak self] in
                guard let self = self else { return }
                self.yAngle = self.normalize2Pi(targetAngle)
                if self.hapticsEnabled {
                    let gen = UIImpactFeedbackGenerator(style: .light)
                    gen.impactOccurred()
                }
            }
        }

        // MARK: - Angle math

        /// Normalize any angle to [0, 2π)
        private func normalize2Pi(_ a: Float) -> Float {
            let twoPi = Float.pi * 2
            var x = fmodf(a, twoPi)
            if x < 0 { x += twoPi }
            return x
        }

        /// Binary midpoint snap: reduce to [0, π), snap at π/2 to 0 or π.
        private func snapTargetMidpoint(currentAngle: Float) -> Float {
            let twoPi = Float.pi * 2
            var x = fmodf(currentAngle, twoPi)
            if x < 0 { x += twoPi }
            let withinHalfTurn = fmodf(x, Float.pi)
            return withinHalfTurn >= (Float.pi / 2) ? Float.pi : 0
        }

        /// Nearest multiple of π to the given angle (… , -π, 0, π, 2π, …)
        private func nearestMultipleOfPi(_ angle: Float) -> Float {
            let k = roundf(angle / Float.pi)
            return k * Float.pi
        }

        // MARK: - Utils

        private func clamp<T: Comparable>(_ x: T, _ a: T, _ b: T) -> T {
            return min(max(x, a), b)
        }
    }
}
