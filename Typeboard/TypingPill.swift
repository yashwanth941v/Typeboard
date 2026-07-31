//
//  TypingPill.swift
//  Typeboard
//
//  A small floating Liquid Glass pill shown at the bottom of the screen
//  while Typeboard is typing. It never steals focus and ignores clicks.
//

import AppKit
import SwiftUI

@MainActor
final class TypingPillWindow: NSWindow {
    static let shared = TypingPillWindow()

    private init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 120, height: 40),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        isOpaque = false
        backgroundColor = .clear
        isMovableByWindowBackground = false
        ignoresMouseEvents = true
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]

        let host = NSHostingView(rootView: TypingPillView())
        contentView = host
    }

    func showPill() {
        guard let screen = NSScreen.main else { return }

        let size = contentView?.fittingSize ?? NSSize(width: 120, height: 40)
        let x = screen.visibleFrame.midX - size.width / 2
        let y = screen.visibleFrame.minY + 24

        setFrame(NSRect(x: x, y: y, width: size.width, height: size.height), display: true)
        alphaValue = 0
        orderFrontRegardless()

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.18
            animator().alphaValue = 1
        }
    }

    func hidePill() {
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.15
            animator().alphaValue = 0
        }, completionHandler: { [weak self] in
            self?.orderOut(nil)
        })
    }
}

struct TypingPillView: View {
    var body: some View {
        Button(action: {}) {
            HStack(spacing: 8) {
                Image(systemName: "doc.on.clipboard")
                    .font(.system(size: 13, weight: .semibold))

                Text("Typing")
                    .font(.system(size: 13, weight: .medium))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .contentShape(Capsule())
        }
        .buttonStyle(.glass)
        .allowsHitTesting(false)
    }
}
