//
//  HotkeyManager.swift
//  Typeboard
//

import Foundation

final class HotkeyManager {
    static let shared = HotkeyManager()

    private init() {}

    func trigger() {
        guard let text = ClipboardManager.shared.currentText() else {
            ClipboardManager.shared.setStatus("Copy text before using the shortcut.")
            return
        }

        let animated = AppSettings.shared.animateTyping

        DispatchQueue.global(qos: .userInitiated).async {
            let success = KeyboardTyper.shared.type(text, animated: animated)

            DispatchQueue.main.async {
                if success {
                    ClipboardManager.shared.setStatus("Typed \(text.count) characters.")
                } else {
                    ClipboardManager.shared.setStatus("Allow Accessibility access in System Settings to type text.")
                }
            }
        }
    }
}
