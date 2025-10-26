import Foundation
import Combine
import UserNotifications
import UIKit
import AudioToolbox

final class TimerManager: ObservableObject {
    @Published var remaining: Int = 0
    @Published var isRunning: Bool = false
    
    private var pendingNotificationId: String?

    /// Prevents timers from starting until explicitly armed by ContentView
    var allowStarts: Bool = false

    private var endTime: Date?
    private var timer: Timer?

    // MARK: - Public API

    func start(seconds: Int) {
        guard allowStarts else { return }
        // Clean up any previous state
        timer?.invalidate()
        timer = nil
        if let id = pendingNotificationId {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
            pendingNotificationId = nil
        }

        endTime = Date().addingTimeInterval(TimeInterval(seconds))
        remaining = seconds
        isRunning = true

        scheduleNotification(in: seconds)     // background path
        startTicking()                        // foreground ticking
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
        if let id = pendingNotificationId {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
            pendingNotificationId = nil
        }
    }

    func resume() {
        // Only resume if we have a remaining value > 0 and are not already running
        guard !isRunning, remaining > 0 else { return }

        endTime = Date().addingTimeInterval(TimeInterval(remaining))
        isRunning = true

        scheduleNotification(in: remaining)   // replace any previous pending
        startTicking()
    }

    func reset() {
        isRunning = false
        endTime = nil
        remaining = 0
        timer?.invalidate()
        timer = nil

        // True reset: clear any pending alert
        if let id = pendingNotificationId {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
            pendingNotificationId = nil
        }
    }

    // MARK: - Private helpers
    private func playCompletionSound() {
        let id = UserDefaults.standard.object(forKey: kTimerSystemSoundIDKey) as? Int
                ?? kTimerSystemSoundIDDefault
        AudioServicesPlaySystemSound(SystemSoundID(id))
    }

    private func startTicking() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    private func tick() {
        guard isRunning, let end = endTime else { return }
        let remainingSeconds = max(0, Int(end.timeIntervalSinceNow.rounded()))
        remaining = remainingSeconds

        if remainingSeconds == 0 {
            completeTimer()
        }
    }

    private func completeTimer() {
        isRunning = false
        endTime = nil
        timer?.invalidate()
        timer = nil
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        playCompletionSound()
    }

    private func scheduleNotification(in seconds: Int) {
        // Replace prior pending request (if any)
        if let id = pendingNotificationId {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
            pendingNotificationId = nil
        }

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
    
    private func cancelNotification() {
        if let id = pendingNotificationId {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
            pendingNotificationId = nil
        }
    }
}
