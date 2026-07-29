//
//  KeyboardTyper.swift
//  Typeboard
//
//  Created by Yashwanth V on 29/07/26.
//

import ApplicationServices
import Foundation

final class KeyboardTyper {
    static let shared = KeyboardTyper()

    private init() {}

    @discardableResult
    func type(_ text: String) -> Bool {
        let accessibilityPrompt = [
            kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true
        ] as CFDictionary

        guard AXIsProcessTrustedWithOptions(accessibilityPrompt) else {
            return false
        }

        guard let eventSource = CGEventSource(stateID: .hidSystemState) else {
            return false
        }

        // Give the shortcut's own modifier keys (Cmd/Shift/etc) time to physically
        // release before we inject text. Otherwise the OS can still see them as
        // held and treat our synthetic keystroke as a command combo instead of
        // plain text, so nothing gets typed.
        Thread.sleep(forTimeInterval: 0.1)

        // CGEventKeyboardSetUnicodeString caps the string at 20 UTF-16 code units
        // per event, so longer clipboard contents need to be sent in chunks.
        let utf16 = Array(text.utf16)
        let chunkSize = 20

        for start in stride(from: 0, to: utf16.count, by: chunkSize) {
            let end = min(start + chunkSize, utf16.count)
            let chunk = Array(utf16[start..<end])

            guard
                let keyDown = CGEvent(keyboardEventSource: eventSource, virtualKey: 0, keyDown: true),
                let keyUp = CGEvent(keyboardEventSource: eventSource, virtualKey: 0, keyDown: false)
            else {
                return false
            }

            keyDown.flags = []
            keyUp.flags = []
            keyDown.keyboardSetUnicodeString(stringLength: chunk.count, unicodeString: chunk)
            keyUp.keyboardSetUnicodeString(stringLength: chunk.count, unicodeString: chunk)
            keyDown.post(tap: .cghidEventTap)
            keyUp.post(tap: .cghidEventTap)
        }

        return true
    }
}
