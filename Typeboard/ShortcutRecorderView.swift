import AppKit
import Carbon.HIToolbox
import KeyboardShortcuts
import SwiftUI

struct ShortcutRecorderView: View {
    let name: KeyboardShortcuts.Name

    @State private var shortcut: KeyboardShortcuts.Shortcut?
    @State private var isRecording = false
    @State private var ignoreNextMouseUp = false

    var body: some View {
        HStack(spacing: 4) {
            Button(action: startRecording) {
                Text(displayText)
                    .frame(maxWidth: .infinity)
                    .frame(minWidth: 130, minHeight: 24)
            }
            .buttonStyle(ShortcutRecorderButtonStyle(isRecording: isRecording))

            if shortcut != nil, !isRecording {
                Button(action: clearShortcut) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Clear shortcut")
            }
        }
        .background {
            LocalKeyMonitor(isActive: isRecording) { event in
                handleEvent(event)
            }
        }
        .onAppear {
            shortcut = KeyboardShortcuts.getShortcut(for: name)
        }
    }

    private var displayText: String {
        if isRecording {
            return "Press shortcut…"
        }

        if let shortcut {
            return "\(shortcut)"
        }

        return "Record Shortcut"
    }

    private func startRecording() {
        isRecording = true
        ignoreNextMouseUp = true
        KeyboardShortcuts.isPaused = true
    }

    private func stopRecording() {
        isRecording = false
        ignoreNextMouseUp = false
        KeyboardShortcuts.isPaused = false
    }

    private func clearShortcut() {
        KeyboardShortcuts.setShortcut(nil, for: name)
        shortcut = nil
    }

    private func handleEvent(_ event: NSEvent) -> NSEvent? {
        if event.type == .leftMouseUp || event.type == .rightMouseUp {
            if ignoreNextMouseUp {
                ignoreNextMouseUp = false
                return event
            }

            stopRecording()
            return event
        }

        guard event.type == .keyDown else {
            return event
        }

        if event.modifiers.isEmpty {
            switch event.specialKey {
            case .delete, .deleteForward, .backspace:
                clearShortcut()
                stopRecording()
                return nil
            default:
                if event.keyCode == kVK_Escape {
                    stopRecording()
                    return nil
                }
            }

            NSSound.beep()
            return nil
        }

        guard
            !event.modifiers.subtracting([.shift, .function]).isEmpty
                || isFunctionKey(event.specialKey),
            let newShortcut = KeyboardShortcuts.Shortcut(event: event)
        else {
            NSSound.beep()
            return nil
        }

        KeyboardShortcuts.setShortcut(newShortcut, for: name)
        shortcut = newShortcut
        stopRecording()
        return nil
    }

    private func isFunctionKey(_ specialKey: NSEvent.SpecialKey?) -> Bool {
        guard let specialKey else { return false }

        switch specialKey {
        case .f1, .f2, .f3, .f4, .f5, .f6, .f7, .f8, .f9, .f10, .f11, .f12,
             .f13, .f14, .f15, .f16, .f17, .f18, .f19, .f20:
            return true
        default:
            return false
        }
    }
}

private struct ShortcutRecorderButtonStyle: ButtonStyle {
    let isRecording: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .multilineTextAlignment(.center)
            .foregroundStyle(isRecording ? Color.accentColor : Color.primary)
            .background {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .strokeBorder(
                        isRecording ? Color.accentColor : Color(nsColor: .separatorColor),
                        lineWidth: isRecording ? 2 : 1
                    )
            }
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}

private struct LocalKeyMonitor: NSViewRepresentable {
    let isActive: Bool
    let onEvent: (NSEvent) -> NSEvent?

    func makeCoordinator() -> Coordinator {
        Coordinator(onEvent: onEvent)
    }

    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        view.isHidden = true
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.setActive(isActive)
    }

    final class Coordinator {
        private var monitor: Any?
        private let onEvent: (NSEvent) -> NSEvent?

        init(onEvent: @escaping (NSEvent) -> NSEvent?) {
            self.onEvent = onEvent
        }

        func setActive(_ isActive: Bool) {
            if isActive {
                start()
            } else {
                stop()
            }
        }

        private func start() {
            guard monitor == nil else { return }

            monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .leftMouseUp, .rightMouseUp]) { [weak self] event in
                self?.onEvent(event) ?? event
            }
        }

        private func stop() {
            guard let monitor else { return }
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }

        deinit {
            stop()
        }
    }
}
