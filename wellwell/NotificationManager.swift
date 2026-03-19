//
//  NotificationManager.swift
//  wellwell
//
//  Created by Eelis Puro on 18.3.2026.
//

import Foundation
import UserNotifications

final class NotificationManager {
    enum NotificationID {
        static let focusEnded = "focus-ended"
        static let breakReminder = "break-reminder"
        static let breakEnded = "break-ended"
        static let workReminder = "work-reminder"
    }

    static let shared = NotificationManager()

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, error in
            if let error = error {
                print("notification permission error: \(error.localizedDescription)")
            }
        }
    }

    func notifyFocusEnded() {
        send(
            identifier: NotificationID.focusEnded,
            title: "Focus session complete",
            body: "Great work! Start your break when you're ready."
        )
    }

    func notifyBreakEnded() {
        send(
            identifier: NotificationID.breakEnded,
            title: "Break finished",
            body: "You're recharged—resume work when you're ready."
        )
    }

    func scheduleBreakFollowUp(after seconds: TimeInterval = 120) {
        schedule(
            identifier: NotificationID.breakReminder,
            title: "Break still waiting",
            body: "You haven't started your break yet. Take a quick reset.",
            after: seconds
        )
    }

    func scheduleWorkFollowUp(after seconds: TimeInterval = 120) {
        schedule(
            identifier: NotificationID.workReminder,
            title: "Time to resume work",
            body: "You haven't resumed work yet. Jump back in when ready.",
            after: seconds
        )
    }

    func cancelBreakFollowUp() {
        removePendingAndDelivered(for: NotificationID.breakReminder)
    }

    func cancelWorkFollowUp() {
        removePendingAndDelivered(for: NotificationID.workReminder)
    }

    private func send(identifier: String, title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }

    private func schedule(identifier: String, title: String, body: String, after seconds: TimeInterval) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }

    private func removePendingAndDelivered(for identifier: String) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        center.removeDeliveredNotifications(withIdentifiers: [identifier])
    }
}
