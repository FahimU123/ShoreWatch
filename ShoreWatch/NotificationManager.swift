// NotificationManager.swift
// ShoreWatch
//
// Requests push notification permission and sends a local notification
// when the threat assessment updates. In production you would replace
// the local notification with an APNs server push to nearby devices.

import UserNotifications

final class NotificationManager {

    static let shared = NotificationManager()
    private init() {}

    // MARK: - Permission

    func requestPermission() async {
        let center = UNUserNotificationCenter.current()
        _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
    }

    // MARK: - Local Alert Notification

    func sendAlert(level: AlertLevel, narrative: String) {
        let center = UNUserNotificationCenter.current()

        let content = UNMutableNotificationContent()
        content.title = "ShoreWatch: \(level.rawValue)"
        content.body = narrative.isEmpty ? level.rawValue : String(narrative.prefix(200))
        content.sound = level == .getOutNow ? .defaultCritical : .default
        content.interruptionLevel = level == .getOutNow ? .critical : .active

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "shorewatch.alert.\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        center.add(request)
    }
}
