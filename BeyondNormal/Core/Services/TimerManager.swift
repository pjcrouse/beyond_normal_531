import Foundation
import Combine
import UserNotifications
import UIKit
import AudioToolbox

final class TimerManager: ObservableObject {
    @Published var remaining: Int = 0
    @Published var isRunning: Bool = false

    /// Prevents timers from starting until explicitly armed by ContentView
    var allowStarts: Bool = false

    private var endTime: Date?
    private var timer: Timer?

    // MARK: - Public API

    func start(seconds: Int) {
        guard allowStarts else { return }
        endTime = Date().addingTimeInterval(TimeInterval(seconds))
        remaining = seconds
        isRunning = true
        scheduleNotification(in: seconds)
        startTicking()
    }

    func pause() {
        isRunning = false
        endTime = nil
        timer?.invalidate()
        timer = nil
    }

    func reset() {
        isRunning = false
        endTime = nil
        remaining = 0
        timer?.invalidate()
        timer = nil
        cancelNotification()
    }

    // MARK: - Private helpers
    private func playCompletionSound() {
        // Strong, decisive swoosh that fits your brand vibe
        AudioServicesPlaySystemSound(SystemSoundID(1057))   // “Mail Sent”
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
    }

    private func scheduleNotification(in seconds: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Rest complete"
        content.body  = "Time to lift."
        content.sound = .default                       // keep default while debugging
        if #available(iOS 15.0, *) {
            content.interruptionLevel = .timeSensitive // ⬅️ helps with Focus modes
        }

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(seconds), repeats: false)

        // Use a unique id so requests don’t overwrite each other
        let id = "bn-rest-\(UUID().uuidString)"
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    private func cancelNotification() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["rest-timer"])
    }
}
