import Foundation
import Combine
import UserNotifications
import UIKit

final class TimerManager: ObservableObject {
    @Published var remaining: Int = 0
    @Published var isRunning: Bool = false

    private var endTime: Date?
    private var cancellable: AnyCancellable?

    func start(seconds: Int) {
        endTime = Date().addingTimeInterval(TimeInterval(seconds))
        remaining = seconds
        isRunning = true
        scheduleNotification(in: seconds)
        startTicking()
    }

    func pause() {
        isRunning = false
        endTime = nil
        cancellable?.cancel()
        cancelNotification()
    }

    func reset() {
        isRunning = false
        endTime = nil
        remaining = 0
        cancellable?.cancel()
        cancelNotification()
    }

    private func startTicking() {
        cancellable?.cancel()
        cancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.tick() }
    }

    private func tick() {
        guard isRunning, let end = endTime else { return }
        let left = max(0, Int(end.timeIntervalSinceNow.rounded()))
        remaining = left
        if left == 0 {
            isRunning = false
            endTime = nil
            cancellable?.cancel()
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }

    private func scheduleNotification(in seconds: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Rest finished"
        content.body = "Time to lift!"
        content.sound = UNNotificationSound.default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(seconds), repeats: false)
        let req = UNNotificationRequest(identifier: "rest-timer", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(req)
    }

    private func cancelNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["rest-timer"])
    }
}
