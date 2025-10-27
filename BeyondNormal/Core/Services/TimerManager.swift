import Foundation
import Combine
import UserNotifications
import UIKit
import AudioToolbox

@MainActor
final class TimerManager: ObservableObject {
    enum Kind { case regular, bbb }

    @Published var remaining: Int = 0
    @Published var isRunning: Bool = false

    /// Prevents timers from starting until explicitly armed by the host view
    var allowStarts: Bool = false

    private var pendingNotificationId: String?
    private var endTime: Date?
    private var timer: Timer?
    private(set) var lastKind: Kind = .regular
    private var lastPlannedDuration: Int = 0

    // MARK: - Public API

    /// Canonical starter (used by UI). Records which kind of timer this is.
    func start(seconds: Int, kind: Kind) {
        guard allowStarts else { return }

        // Clean up any previous state
        timer?.invalidate()
        timer = nil
        cancelNotification()

        lastKind = kind
        lastPlannedDuration = seconds

        endTime = Date().addingTimeInterval(TimeInterval(seconds))
        remaining = seconds
        isRunning = true

        scheduleNotification(in: seconds)
        startTicking()
    }

    /// Backward-compatible wrapper that reuses the last known kind (defaults to .regular).
    func start(seconds: Int) {
        start(seconds: seconds, kind: lastKind)
    }

    func pause() {
        guard isRunning else { return }
        isRunning = false
        timer?.invalidate()
        timer = nil

        // Freeze remaining so we can resume later
        if let end = endTime {
            remaining = max(1, Int(end.timeIntervalSinceNow.rounded()))
        }
        endTime = nil

        // Paused = no alert should fire
        cancelNotification()
    }

    func resume() {
        guard !isRunning, remaining > 0 else { return }

        endTime = Date().addingTimeInterval(TimeInterval(remaining))
        isRunning = true

        scheduleNotification(in: remaining)
        startTicking()
    }

    func reset() {
        isRunning = false
        endTime = nil
        remaining = 0
        timer?.invalidate()
        timer = nil

        // True reset: clear any pending alert
        cancelNotification()
    }

    // MARK: - ± buttons support (temporary per-session adjust)

    /// Temporarily adjusts the active countdown (or pending time) by deltaSeconds.
    /// Floors at 60 seconds for safety.
    func adjust(by deltaSeconds: Int) {
        guard isRunning || remaining > 0 else { return }

        let now = Date()
        let baseRemaining: Int
        if let end = endTime {
            baseRemaining = max(0, Int(end.timeIntervalSince(now)))
        } else {
            baseRemaining = remaining
        }

        let newRemaining = max(60, baseRemaining + deltaSeconds)   // ≤— 60s floor
        remaining = newRemaining
        endTime = now.addingTimeInterval(TimeInterval(newRemaining))

        scheduleNotification(in: newRemaining)
    }

    /// Long-press action: persist the *current* remaining time as the new default for this kind.
    func persistCurrentAsDefault(_ settings: ProgramSettings) {
        let duration = max(60, remaining)
        switch lastKind {
        case .regular: settings.timerRegularSec = duration
        case .bbb:     settings.timerBBBSec     = duration
        }
    }

    /// On app resume, recompute remaining from the stored endTime to correct drift.
    func resyncOnForeground() {
        guard isRunning, let end = endTime else { return }
        remaining = max(0, Int(end.timeIntervalSinceNow.rounded()))
        if remaining == 0 { completeTimer() }
    }

    // MARK: - Internals

    private func playCompletionSound() {
        let id = UserDefaults.standard.object(forKey: kTimerSystemSoundIDKey) as? Int
                ?? kTimerSystemSoundIDDefault
        AudioServicesPlaySystemSound(SystemSoundID(id))
    }

    private func startTicking() {
        timer?.invalidate()
        // Timer is scheduled on the runloop; we’re @MainActor so UI updates are safe.
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            // Hop back to main explicitly to be extra safe with @MainActor semantics.
            Task { @MainActor in
                self?.tick()
            }
        }
    }

    private func tick() {
        guard isRunning, let end = endTime else { return }
        let s = max(0, Int(end.timeIntervalSinceNow.rounded()))
        remaining = s
        if s == 0 { completeTimer() }
    }

    private func completeTimer() {
        isRunning = false
        endTime = nil
        timer?.invalidate()
        timer = nil
        cancelNotification()
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        playCompletionSound()
    }

    private func scheduleNotification(in seconds: Int) {
        // Replace prior pending request (if any)
        cancelNotification()

        let content = UNMutableNotificationContent()
        content.title = "Rest complete"
        content.body  = "Time to lift."
        content.sound = .default
        if #available(iOS 15.0, *) {
            content.interruptionLevel = .timeSensitive
        }

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(seconds), repeats: false)
        let id = "bn-rest-\(UUID().uuidString)"
        pendingNotificationId = id
        let req = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(req)
    }

    /// Remove any existing pending rest alert.
    private func cancelNotification() {
        if let id = pendingNotificationId {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
            pendingNotificationId = nil
        }
    }
}
