//
//  AppDelegate.swift
//  Typeboard
//

import AppKit
import KeyboardShortcuts

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        UserAlert.requestNotificationPermissionIfNeeded()

        KeyboardShortcuts.onKeyUp(for: .typeClipboard) {
            Task { @MainActor in
                HotkeyManager.shared.trigger()
            }
        }
        KeyboardShortcuts.onKeyUp(for: .answerWithAI) {
            Task { @MainActor in
                AIManager.shared.trigger()
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        OllamaManager.shared.stopServer()
        OllamaManager.shared.cleanupTempFiles()
    }
}
