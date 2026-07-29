import SwiftUI
import KeyboardShortcuts
import Combine

struct ContentView: View {
    @StateObject private var clipboard = ClipboardManager.shared
    @ObservedObject private var settings = AppSettings.shared
    private let clipboardRefreshTimer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()

    var body: some View {
        Form {
            Section {
                LabeledContent("Type Clipboard") {
                    ShortcutRecorderView(name: .typeClipboard)
                }
            } footer: {
                Text("Click the field, then press the key combination you want to use.")
            }

            Section {
                Toggle("Animate typing", isOn: $settings.animateTyping)
            } footer: {
                Text("Simulates human typing speed instead of pasting text instantly.")
            }

            Section("Clipboard Preview") {
                Group {
                    if let text = clipboard.text, !text.isEmpty {
                        Text(text)
                            .textSelection(.enabled)
                    } else {
                        Text("Copy some text to see it here.")
                            .foregroundStyle(.secondary)
                    }
                }
                .lineLimit(4)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Section {
                Text(clipboard.status)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 420, height: 260)
        .onAppear {
            clipboard.refresh()
        }
        .onReceive(clipboardRefreshTimer) { _ in
            clipboard.refresh()
        }
        .onGlobalKeyboardShortcut(.typeClipboard, type: .keyUp) {
            HotkeyManager.shared.trigger()
        }
    }
}

#Preview {
    ContentView()
}
