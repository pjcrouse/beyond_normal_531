import UserNotifications

final class LocalNotifDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = LocalNotifDelegate()

    // Show banner + sound even when app is foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .list, .sound])
    }
}
