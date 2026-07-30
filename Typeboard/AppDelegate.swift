//
//  AppDelegate.swift
//  Typeboard
//

import AppKit
import KeyboardShortcuts

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        KeyboardShortcuts.onKeyUp(for: .typeClipboard) {
            Task { @MainActor in
                HotkeyManager.shared.trigger()
            }
        }
    }
}
