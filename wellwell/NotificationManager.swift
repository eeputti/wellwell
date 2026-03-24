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
            title: L10n.tr("notification_focus_complete_title"),
            body: L10n.tr("notification_focus_complete_body")
        )
    }

    func notifyBreakEnded() {
        send(
            identifier: NotificationID.breakEnded,
            title: L10n.tr("notification_break_finished_title"),
            body: L10n.tr("notification_break_finished_body")
        )
    }

    func scheduleBreakFollowUp(after seconds: TimeInterval = 120) {
        schedule(
            identifier: NotificationID.breakReminder,
            title: L10n.tr("notification_break_waiting_title"),
            body: L10n.tr("notification_break_waiting_body"),
            after: seconds
        )
    }

    func scheduleWorkFollowUp(after seconds: TimeInterval = 120) {
        schedule(
            identifier: NotificationID.workReminder,
            title: L10n.tr("notification_resume_work_title"),
            body: L10n.tr("notification_resume_work_body"),
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
        
        removePendingAndDelivered(for: identifier)

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                print("failed to send notification (\(identifier)): \(error.localizedDescription)")
            }
        }
    }

    private func schedule(identifier: String, title: String, body: String, after seconds: TimeInterval) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, seconds), repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        removePendingAndDelivered(for: identifier)

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                print("failed to schedule notification (\(identifier)): \(error.localizedDescription)")
            }
        }
    }

    private func removePendingAndDelivered(for identifier: String) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        center.removeDeliveredNotifications(withIdentifiers: [identifier])
    }
}
