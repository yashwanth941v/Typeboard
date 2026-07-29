//
//  KeyboardTyper.swift
//  Typeboard
//

import ApplicationServices
import Foundation

final class KeyboardTyper {
    static let shared = KeyboardTyper()

    private init() {}

    /// Types `text` into the frontmost app.
    /// - Parameter animated: when true, characters are sent one at a time with
    ///   a small randomized delay between them to simulate human typing speed.
    ///   When false, the text is sent in as few events as possible, instantly.
    @discardableResult
    func type(_ text: String, animated: Bool) -> Bool {
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

        if animated {
            for character in text {
                guard postChunk(Array(String(character).utf16), source: eventSource) else {
                    return false
                }
                let delayMs = Double.random(in: 5...15)
                Thread.sleep(forTimeInterval: delayMs / 1000)
            }
            return true
        }

        // CGEventKeyboardSetUnicodeString caps the string at 20 UTF-16 code units
        // per event, so longer clipboard contents need to be sent in chunks.
        let utf16 = Array(text.utf16)
        let chunkSize = 20

        for start in stride(from: 0, to: utf16.count, by: chunkSize) {
            let end = min(start + chunkSize, utf16.count)
            let chunk = Array(utf16[start..<end])
            guard postChunk(chunk, source: eventSource) else {
                return false
            }
        }

        return true
    }

    private func postChunk(_ chunk: [UniChar], source: CGEventSource) -> Bool {
        guard
            let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true),
            let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false)
        else {
            return false
        }

        keyDown.flags = []
        keyUp.flags = []
        keyDown.keyboardSetUnicodeString(stringLength: chunk.count, unicodeString: chunk)
        keyUp.keyboardSetUnicodeString(stringLength: chunk.count, unicodeString: chunk)
        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
        return true
    }
}
