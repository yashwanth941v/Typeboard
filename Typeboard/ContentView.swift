import SwiftUI

struct ContentView: View {
    @ObservedObject private var settings = AppSettings.shared

    var body: some View {
        Form {
            Section {
                LabeledContent("Type Clipboard") {
                    ShortcutRecorderView(name: .typeClipboard)
                }
            } footer: {
                Text("Pastes copied clipboard text. Esc cancels mid-type; Cmd+Z right after undoes the whole block.")
            }

            Section {
                Picker("Speed", selection: $settings.typingSpeed) {
                    ForEach(TypingSpeed.allCases) { speed in
                        Text(speed.displayName).tag(speed)
                    }
                }
            } footer: {
                Text(settings.typingSpeed.footerDescription)
            }

            Section {
                HStack(spacing: 12) {
                    Image("ProfilePicture")
                        .resizable()
                        .frame(width: 32, height: 32)
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 1) {
                        Text("Built and developed by Yashwanth V")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Link("yashwanth941v.com", destination: URL(string: "https://yashwanth941v.com/")!)
                            .font(.caption)
                            .foregroundStyle(.tint)
                    }

                    Spacer()
                }
                .padding(.vertical, 4)
            }
        }
        .formStyle(.grouped)
        .frame(width: 420, height: 380)
        .background(FocusDismissMonitor())
    }
}

#Preview {
    ContentView()
}
