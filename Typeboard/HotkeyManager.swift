//
//  HotkeyManager.swift
//  Typeboard
//
//  Created by Yashwanth V on 29/07/26.
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

        if KeyboardTyper.shared.type(text) {
            ClipboardManager.shared.setStatus("Typed \(text.count) characters.")
        } else {
            ClipboardManager.shared.setStatus("Allow Accessibility access in System Settings to type text.")
        }
    }
}
