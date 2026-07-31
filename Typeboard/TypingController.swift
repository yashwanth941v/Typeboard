//
//  TypingController.swift
//  Typeboard
//
//  Orchestrates an animated typing session: paces output by speed/content
//  size, stops the moment focus moves away, and tracks enough state for
//  InputInterceptor to support Esc-cancel and block-undo.
//

import AppKit
@preconcurrency import ApplicationServices
import Foundation

enum TypingResult: Sendable {
    case completed
    case cancelled
    case interrupted // frontmost app or focused field changed mid-typing
    case failed
}

final class TypingController: @unchecked Sendable {
    nonisolated static let shared = TypingController()

    nonisolated(unsafe) private(set) var isTyping = false
    nonisolated(unsafe) private var cancelRequested = false

    // So a Cmd+Z / Cmd+Shift+Z right after a session can undo or redo the
    // whole block at once, instead of touching the app's own undo stack.
    nonisolated(unsafe) private var undoText: String?
    nonisolated(unsafe) private var redoText: String?

    nonisolated private init() {}

    nonisolated private func syncInputInterceptor() {
        let needsTap = isTyping
            || !(undoText?.isEmpty ?? true)
            || !(redoText?.isEmpty ?? true)

        if Thread.isMainThread {
            MainActor.assumeIsolated {
                if needsTap {
                    InputInterceptor.shared.start()
                } else {
                    InputInterceptor.shared.stop()
                }
            }
        } else {
            DispatchQueue.main.sync {
                MainActor.assumeIsolated {
                    if needsTap {
                        InputInterceptor.shared.start()
                    } else {
                        InputInterceptor.shared.stop()
                    }
                }
            }
        }
    }

    nonisolated func cancel() {
        cancelRequested = true
    }

    /// Returns true if it consumed the undo (i.e. it removed the block itself
    /// and the Cmd+Z that triggered this should NOT be forwarded to the app).
    nonisolated func consumeUndoIfAvailable() -> Bool {
        guard let text = undoText, !text.isEmpty else { return false }
        undoText = nil
        redoText = text
        deleteText(text)
        syncInputInterceptor()
        return true
    }

    /// Returns true if it consumed the redo (i.e. it retyped the block itself
    /// and the Cmd+Shift+Z that triggered this should NOT be forwarded to the app).
    nonisolated func consumeRedoIfAvailable() -> Bool {
        guard let text = redoText, !text.isEmpty else { return false }
        redoText = nil
        undoText = text
        retypeText(text)
        syncInputInterceptor()
        return true
    }

    nonisolated private func deleteText(_ text: String) {
        DispatchQueue.global(qos: .userInitiated).async {
            // Brief pause so the swallowed Cmd+Z settles before we delete.
            Thread.sleep(forTimeInterval: 0.05)
            KeyboardTyper.postBackspaces(text.count, delayBetween: 0.003)
        }
    }

    nonisolated private func retypeText(_ text: String) {
        DispatchQueue.global(qos: .userInitiated).async {
            KeyboardTyper.postText(text)
        }
    }

    @discardableResult
    nonisolated func startTyping(
        _ text: String,
        speed: TypingSpeed,
        initialPID: pid_t?,
        initialFocus: AXUIElement?
    ) -> TypingResult {
        guard !isTyping else { return .failed }
        isTyping = true
        cancelRequested = false
        undoText = nil
        redoText = nil
        syncInputInterceptor()
        showTypingPill()
        defer {
            isTyping = false
            hideTypingPill()
            syncInputInterceptor()
        }

        guard KeyboardTyper.ensureAccessibility(prompt: false) else { return .failed }

        Thread.sleep(forTimeInterval: 0.1)

        var typedSoFar = ""

        func stillFocused() -> Bool {
            if cancelRequested { return false }
            let currentPID = DispatchQueue.main.sync {
                MainActor.assumeIsolated {
                    NSWorkspace.shared.frontmostApplication?.processIdentifier
                }
            }
            if let initialPID, currentPID != initialPID { return false }
            if let initialFocus {
                let current = DispatchQueue.main.sync {
                    MainActor.assumeIsolated { focusedElement() }
                }
                guard let current, CFEqual(current, initialFocus) else { return false }
            }
            return true
        }

        if speed == .instant {
            guard stillFocused(), KeyboardTyper.postText(text) else { return .failed }
            finalizeUndo(with: text)
            return .completed
        }

        let (unit, delayRange) = plan(for: text, speed: speed)
        let chunks = split(text, by: unit)
        let useNaturalRhythm = speed != .fast
        let easeOut = speed == .fast || speed == .medium || speed == .slow
        let delaySteps = chunks.filter {
            !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }.count
        var completedDelaySteps = 0

        for chunk in chunks {
            guard stillFocused() else {
                finalizeUndo(with: typedSoFar)
                return cancelRequested ? .cancelled : .interrupted
            }

            guard KeyboardTyper.postText(chunk) else { return .failed }
            typedSoFar += chunk

            // Whitespace carries no visual "typing" to animate — post it and
            // move straight on instead of pausing after it.
            if chunk.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                continue
            }

            let progress = delaySteps > 1
                ? Double(completedDelaySteps) / Double(delaySteps - 1)
                : 0
            completedDelaySteps += 1

            Thread.sleep(forTimeInterval: delay(
                in: delayRange,
                natural: useNaturalRhythm,
                progress: progress,
                easeOut: easeOut
            ))
        }

        finalizeUndo(with: typedSoFar)
        return .completed
    }

    nonisolated func startTypingFromHotkey(_ text: String, speed: TypingSpeed) {
        let initialPID: pid_t?
        let initialFocus: AXUIElement?

        if Thread.isMainThread {
            (initialPID, initialFocus) = MainActor.assumeIsolated {
                (NSWorkspace.shared.frontmostApplication?.processIdentifier, focusedElement())
            }
        } else {
            initialPID = nil
            initialFocus = nil
        }

        DispatchQueue.global(qos: .userInitiated).async {
            switch self.startTyping(text, speed: speed, initialPID: initialPID, initialFocus: initialFocus) {
            case .failed:
                Task { @MainActor in
                    UserAlert.showWarning("Typeboard needs Accessibility access in System Settings to type for you.")
                }
            case .completed, .cancelled, .interrupted:
                break
            }
        }
    }

    nonisolated private func finalizeUndo(with text: String) {
        guard !text.isEmpty else {
            syncInputInterceptor()
            return
        }
        undoText = text
        redoText = nil
        syncInputInterceptor()
    }

    // MARK: - Typing pill overlay

    nonisolated private func showTypingPill() {
        DispatchQueue.main.async {
            MainActor.assumeIsolated {
                TypingPillWindow.shared.showPill()
            }
        }
    }

    nonisolated private func hideTypingPill() {
        DispatchQueue.main.async {
            MainActor.assumeIsolated {
                TypingPillWindow.shared.hidePill()
            }
        }
    }

    // MARK: - Timing

    nonisolated private func delay(
        in range: ClosedRange<Double>,
        natural: Bool,
        progress: Double,
        easeOut: Bool
    ) -> TimeInterval {
        var ms: Double
        if natural {
            // Averaging two draws plus an occasional longer pause reads as
            // natural rhythm rather than uniform jitter.
            let a = Double.random(in: range)
            let b = Double.random(in: range)
            ms = (a + b) / 2
            if Double.random(in: 0...1) < 0.06 {
                ms += Double.random(in: 80...220)
            }
        } else {
            // Fast mode: flat random only — no extra pauses.
            ms = Double.random(in: range)
        }

        if easeOut {
            let clamped = min(max(progress, 0), 1)
            let eased = 1 - pow(1 - clamped, 2)
            let minFactor = 0.12
            ms *= 1 - eased * (1 - minFactor)
        }

        return ms / 1000
    }

    nonisolated private enum TypingUnit { case character, word, line }

    nonisolated private func plan(for text: String, speed: TypingSpeed) -> (TypingUnit, ClosedRange<Double>) {
        let length = text.count
        switch speed {
        case .instant:
            return (.character, 0...0) // unused — instant posts all at once
        case .slow:
            return (.character, 45...110)
        case .medium:
            return (.character, 18...45)
        case .fast:
            // Always the fastest animated mode — chunk aggressively and skip
            // natural pauses so long strings don't lag behind Auto.
            if length <= 80 {
                return (.character, 1...3)
            } else if length <= 400 {
                return (.word, 1...4)
            } else {
                return (.line, 1...3)
            }
        case .auto:
            if length <= 60 {
                return (.character, 22...55)
            } else if length <= 400 {
                return (.word, 35...80)
            } else {
                return (.line, 15...40)
            }
        }
    }

    // MARK: - Splitting (each function's output concatenates back to the original text)

    nonisolated private func split(_ text: String, by unit: TypingUnit) -> [String] {
        switch unit {
        case .character:
            return text.map { String($0) }
        case .word:
            return splitPreservingWhitespace(text)
        case .line:
            return splitIntoLines(text)
        }
    }

    nonisolated private func splitPreservingWhitespace(_ text: String) -> [String] {
        var units: [String] = []
        var current = ""
        for char in text {
            current.append(char)
            if char == " " || char == "\n" || char == "\t" {
                units.append(current)
                current = ""
            }
        }
        if !current.isEmpty { units.append(current) }
        return units
    }

    nonisolated private func splitIntoLines(_ text: String) -> [String] {
        var lines: [String] = []
        var current = ""
        for char in text {
            current.append(char)
            if char == "\n" {
                lines.append(current)
                current = ""
            }
        }
        if !current.isEmpty { lines.append(current) }
        return lines
    }

    // MARK: - Focus tracking

    nonisolated private func focusedElement() -> AXUIElement? {
        let systemWide = AXUIElementCreateSystemWide()
        var value: AnyObject?
        guard AXUIElementCopyAttributeValue(systemWide, kAXFocusedUIElementAttribute as CFString, &value) == .success,
              let value else {
            return nil
        }
        return (value as! AXUIElement)
    }
}
