//
//  ClipboardManager.swift
//  Typeboard
//
//  Created by Yashwanth V on 29/07/26.
//

import AppKit

final class ClipboardManager {
    static let shared = ClipboardManager()

    private init() {}

    func currentText() -> String? {
        NSPasteboard.general.string(forType: .string)
    }
}
