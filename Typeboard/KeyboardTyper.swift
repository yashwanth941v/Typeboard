//
//  KeyboardTyper.swift
//  Typeboard
//
//  Low-level helpers for posting synthetic keyboard events. No timing or
//  cancellation logic lives here — see TypingController for that.
//

import ApplicationServices
import Foundation

enum KeyboardTyper {
    nonisolated static func ensureAccessibility(prompt: Bool = false) -> Bool {
        if prompt {
            let options = [
                kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true
            ] as CFDictionary
            return AXIsProcessTrustedWithOptions(options)
        }
        return AXIsProcessTrusted()
    }

    @discardableResult
    nonisolated static func postText(_ text: String) -> Bool {
        guard let source = CGEventSource(stateID: .hidSystemState) else { return false }

        let utf16 = Array(text.utf16)
        let chunkSize = 20

        for start in stride(from: 0, to: utf16.count, by: chunkSize) {
            let end = min(start + chunkSize, utf16.count)
            guard postChunk(Array(utf16[start..<end]), source: source) else { return false }
        }
        return true
    }

    @discardableResult
    nonisolated static func postBackspaces(_ count: Int, delayBetween: TimeInterval = 0) -> Bool {
        guard count > 0, let source = CGEventSource(stateID: .hidSystemState) else { return false }

        let deleteKeyCode: CGKeyCode = 51

        for index in 0..<count {
            guard
                let keyDown = CGEvent(keyboardEventSource: source, virtualKey: deleteKeyCode, keyDown: true),
                let keyUp = CGEvent(keyboardEventSource: source, virtualKey: deleteKeyCode, keyDown: false)
            else {
                return false
            }
            keyDown.flags = []
            keyUp.flags = []
            keyDown.post(tap: .cghidEventTap)
            keyUp.post(tap: .cghidEventTap)

            if delayBetween > 0, index < count - 1 {
                Thread.sleep(forTimeInterval: delayBetween)
            }
        }
        return true
    }

    private nonisolated static func postChunk(_ chunk: [UniChar], source: CGEventSource) -> Bool {
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
