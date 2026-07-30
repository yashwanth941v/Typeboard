//
//  FocusDismissMonitor.swift
//  Typeboard
//

import AppKit
import SwiftUI

/// Resigns text-field focus when the user clicks elsewhere in the window.
struct FocusDismissMonitor: NSViewRepresentable {
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> NSView {
        NSView(frame: .zero)
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.installMonitor(for: nsView.window)
    }

    final class Coordinator {
        private weak var observedWindow: NSWindow?
        private var monitor: Any?

        func installMonitor(for window: NSWindow?) {
            guard window !== observedWindow else { return }
            removeMonitor()
            observedWindow = window
            guard let window else { return }

            monitor = NSEvent.addLocalMonitorForEvents(matching: .leftMouseDown) { event in
                guard event.window === window, let contentView = window.contentView else {
                    return event
                }

                let point = contentView.convert(event.locationInWindow, from: nil)
                guard let hit = contentView.hitTest(point) else {
                    window.makeFirstResponder(nil)
                    return event
                }

                if !Self.isTextInput(hit) {
                    window.makeFirstResponder(nil)
                }
                return event
            }
        }

        private static func isTextInput(_ view: NSView) -> Bool {
            var candidate: NSView? = view
            while let current = candidate {
                if current is NSTextView { return true }
                if current is NSTextField { return true }
                candidate = current.superview
            }
            return false
        }

        private func removeMonitor() {
            if let monitor {
                NSEvent.removeMonitor(monitor)
            }
            monitor = nil
        }

        deinit {
            removeMonitor()
        }
    }
}
