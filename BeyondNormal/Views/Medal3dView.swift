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

    // MARK: - Coordinator (Y-only spin on parent; fixed pose on child)
    final class Coordinator: NSObject {
        var parent: Medal3DView
        weak var spinner: SCNNode?

        // Continuous Y angle for 360° spinning (radians, unbounded; normalized when used)
        var yAngle: Float = 0

        // Gesture state
        private var lastX: CGFloat = 0

        // Tuning
        private let pxToRad: CGFloat = 0.01     // drag sensitivity (pixels → radians)
        private let jitterDeadzone: CGFloat = 1.2 // ignore tiny finger jitter (px)

        // Snapping with hysteresis:
        // We snap between front (0) and back (π) faces. Hysteresis avoids oscillation near π/2.
        private let snapHysteresis: Float = 0.25 // radians (~14°) band around midpoint
        private var lastSnapTarget: Float = 0    // either 0 (front) or π (back)

        init(_ parent: Medal3DView) { self.parent = parent }

        @objc func handlePan(_ pan: UIPanGestureRecognizer) {
            guard let node = spinner else { return }
            let p = pan.translation(in: pan.view)

            switch pan.state {
            case .began:
                lastX = p.x

            case .changed:
                var dx = p.x - lastX
                // small deadzone to reduce jitter
                if abs(dx) < jitterDeadzone { dx = 0 }
                lastX = p.x

                // 360° spin: accumulate and normalize to [0, 2π)
                yAngle += Float(dx * pxToRad)
                yAngle = normalize2Pi(yAngle)

                // Only rotate Y on the parent; child holds fixed X/Z
                node.eulerAngles = SCNVector3(0, yAngle, 0)

            case .ended, .cancelled:
                // Pick target (0 or π) with hysteresis to avoid ping-ponging at midpoint.
                let target = snapTargetWithHysteresis(currentAngle: yAngle,
                                                      lastTarget: lastSnapTarget,
                                                      band: snapHysteresis)

                // Animate to the nearest equivalent of target (… -2π, 0, +2π, …) relative to current y
                let goal = nearestEquivalent(of: target, to: yAngle)

                let action = SCNAction.rotateTo(x: 0,
                                                y: CGFloat(goal),
                                                z: 0,
                                                duration: 0.35,
                                                usesShortestUnitArc: true)
                action.timingMode = .easeOut
                node.runAction(action)

                yAngle = normalize2Pi(goal)
                lastSnapTarget = target

            default:
                break
            }
        }

        // MARK: - Helpers

        /// Normalize any angle to [0, 2π)
        private func normalize2Pi(_ a: Float) -> Float {
            let twoPi = Float.pi * 2
            var x = fmodf(a, twoPi)
            if x < 0 { x += twoPi }
            return x
        }

        /// Return the snap target (0 or π) using a hysteresis band around π/2 so we don't flicker.
        private func snapTargetWithHysteresis(currentAngle: Float,
                                              lastTarget: Float,
                                              band: Float) -> Float {
            // Reduce to a 0..π window so front/back decisions are periodic with period π
            let within = fmodf(currentAngle, Float.pi)
            let midpoint = Float.pi / 2

            var target = lastTarget
            if lastTarget == 0 {
                // From front → back only if sufficiently past midpoint + band
                if within >= (midpoint + band) { target = Float.pi }
                // From front stay front if below midpoint - band (or in-band)
                else if within <= (midpoint - band) { target = 0 }
                // else within hysteresis band: keep last target (front)
            } else { // lastTarget == π
                // From back → front only if sufficiently before midpoint - band
                if within <= (midpoint - band) { target = 0 }
                // From back stay back if above midpoint + band (or in-band)
                else if within >= (midpoint + band) { target = Float.pi }
                // else within hysteresis band: keep last target (back)
            }
            return target
        }

        /// Choose the nearest 2π-equivalent of `target` to the current `angle`
        private func nearestEquivalent(of target: Float, to angle: Float) -> Float {
            let twoPi = Float.pi * 2
            // Base candidate near angle by shifting target by k·2π
            var k = roundf((angle - target) / twoPi)
            var candidate = target + k * twoPi
            // Check neighbors ±2π for an even closer absolute difference
            if abs(candidate - angle) > abs((candidate + twoPi) - angle) { candidate += twoPi }
            if abs(candidate - angle) > abs((candidate - twoPi) - angle) { candidate -= twoPi }
            return candidate
        }
    }
}
