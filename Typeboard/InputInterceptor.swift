//
//  InputInterceptor.swift
//  Typeboard
//
//  Global low-level event tap: lets Esc cancel an in-progress typing session,
//  and lets a Cmd+Z right after a session remove the whole typed block at
//  once instead of one character at a time.
//

import CoreGraphics
import Foundation

@MainActor
final class InputInterceptor {
    static let shared = InputInterceptor()

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    private init() {}

    func start() {
        guard eventTap == nil else { return }

        let mask: CGEventMask = CGEventMask(1 << CGEventType.keyDown.rawValue)

        guard let tap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: typeboardEventTapCallback,
            userInfo: nil
        ) else {
            return
        }

        eventTap = tap
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
    }

    func stop() {
        guard let tap = eventTap else { return }

        CGEvent.tapEnable(tap: tap, enable: false)
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil
    }

    nonisolated func handle(event: CGEvent, type: CGEventType) -> Unmanaged<CGEvent>? {
        MainActor.assumeIsolated {
            if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
                if let eventTap {
                    CGEvent.tapEnable(tap: eventTap, enable: true)
                }
                return Unmanaged.passRetained(event)
            }

            let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
            let flags = event.flags

            if keyCode == 53, TypingController.shared.isTyping {
                TypingController.shared.cancel()
                return nil
            }

            if keyCode == 6, flags.contains(.maskCommand) {
                if flags.contains(.maskShift) {
                    if TypingController.shared.consumeRedoIfAvailable() {
                        return nil
                    }
                } else {
                    if TypingController.shared.consumeUndoIfAvailable() {
                        return nil
                    }
                }
            }

            return Unmanaged.passRetained(event)
        }
    }
}

private nonisolated func typeboardEventTapCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    refcon: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    MainActor.assumeIsolated {
        InputInterceptor.shared.handle(event: event, type: type)
    }
}
