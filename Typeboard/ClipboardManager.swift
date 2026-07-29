//
//  ClipboardManager.swift
//  Typeboard
//
//  Created by Yashwanth V on 29/07/26.
//

import AppKit
import Combine

final class ClipboardManager: ObservableObject {
    static let shared = ClipboardManager()

    @Published private(set) var text: String?
    @Published private(set) var status = "Ready"

    private var lastChangeCount = -1

    private init() {}

    func currentText() -> String? {
        refresh()
        return text
    }

    func refresh() {
        let pasteboard = NSPasteboard.general

        guard pasteboard.changeCount != lastChangeCount else { return }

        lastChangeCount = pasteboard.changeCount
        text = pasteboard.string(forType: .string)
    }

    func setStatus(_ status: String) {
        self.status = status
    }
}
