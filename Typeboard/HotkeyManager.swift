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
            print("Clipboard empty.")
            return
        }

        KeyboardTyper.shared.type(text)
    }
}
