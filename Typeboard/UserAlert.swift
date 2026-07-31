//
//  UserAlert.swift
//  Typeboard
//

import AppKit
import UserNotifications

enum UserAlert {
    static func requestNotificationPermissionIfNeeded() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    @MainActor
    static func showWarning(_ message: String) {
        NSApp.activate(ignoringOtherApps: true)

        if let window = NSApp.keyWindow ?? NSApp.windows.first(where: { $0.isVisible && $0.canBecomeKey }) {
            window.makeKeyAndOrderFront(nil)

            let alert = NSAlert()
            alert.messageText = message
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")
            alert.beginSheetModal(for: window)
            return
        }

        postNotification(message)
    }

    private static func postNotification(_ message: String) {
        let content = UNMutableNotificationContent()
        content.title = "Typeboard"
        content.body = message

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }
}
