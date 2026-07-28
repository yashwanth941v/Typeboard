import SwiftUI
import KeyboardShortcuts

struct ContentView: View {
    var body: some View {
        Form {
            Section {
                LabeledContent("Type Clipboard") {
                    ShortcutRecorderView(name: .typeClipboard)
                }
            } footer: {
                Text("Click the field, then press the key combination you want to use.")
            }
        }
        .formStyle(.grouped)
        .fixedSize()
        .onGlobalKeyboardShortcut(.typeClipboard, type: .keyUp) {
            HotkeyManager.shared.trigger()
        }
    }
}

#Preview {
    ContentView()
}
