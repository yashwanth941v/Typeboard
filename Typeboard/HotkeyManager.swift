//
//  HotkeyManager.swift
//  Typeboard
//

import Foundation

@MainActor
final class HotkeyManager {
    static let shared = HotkeyManager()

    private init() {}

    func trigger() {
        guard let text = ClipboardManager.shared.currentText() else { return }

        let speed = AppSettings.shared.typingSpeed

        TypingController.shared.startTypingFromHotkey(text, speed: speed)
    }
}
