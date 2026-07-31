import SwiftUI

struct ContentView: View {
    @ObservedObject private var settings = AppSettings.shared
    @State private var showRemoveConfirmation = false
    @State private var isRemovingModel = false
    @State private var showAIUnderDevelopment = false

    var body: some View {
        TabView {
            typingTab
                .tabItem {
                    Label("Typing", systemImage: "keyboard")
                }

            aiTab
                .tabItem {
                    Label("AI", systemImage: "sparkles")
                }

            aboutTab
                .tabItem {
                    Label("About", systemImage: "person.circle")
                }
        }
        .frame(width: 420, height: 480)
        .background(FocusDismissMonitor())
        .task {
            await settings.checkOllamaStatus()
        }
        .confirmationDialog(
            "Remove this model?",
            isPresented: $showRemoveConfirmation,
            actions: {
                Button("Remove", role: .destructive) {
                    Task { await removeModel() }
                }
                Button("Cancel", role: .cancel) {}
            },
            message: {
                Text("The model will be deleted from disk. You can download it again later.")
            }
        )
    }

    // MARK: - Typing Tab

    private var typingTab: some View {
        Form {
            Section {
                Toggle("Enable Typing", isOn: $settings.isTypingEnabled)
            } footer: {
                Text(settings.isTypingEnabled
                     ? "Typing is on. The Type Clipboard shortcut is active."
                     : "Typing is off. The Type Clipboard shortcut is disabled.")
            }

            if settings.isTypingEnabled {
                Section {
                    LabeledContent("Type Clipboard") {
                        ShortcutRecorderView(name: .typeClipboard)
                    }
                } footer: {
                    Text("Type Clipboard pastes the copied text into whatever you're typing in.")
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
            }
        }
        .formStyle(.grouped)
    }

    // MARK: - About Tab

    private var aboutTab: some View {
        Form {
            Section {
                VStack(spacing: 10) {
                    Image(nsImage: NSApplication.shared.applicationIconImage)
                        .resizable()
                        .frame(width: 72, height: 72)
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                    Text("Typeboard")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("Version 1.0")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
            }

            Section {
                HStack(spacing: 10) {
                    Image("ProfilePicture")
                        .resizable()
                        .frame(width: 22, height: 22)
                        .clipShape(Circle())

                    Text("Yashwanth V")
                        .font(.callout)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text("Developer")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(.vertical, 2)

                LinkRow(
                    title: "Website",
                    url: URL(string: "https://yashwanth941v.com/")!,
                    color: .blue,
                    icon: .system("globe")
                )

                LinkRow(
                    title: "Twitter / X",
                    url: URL(string: "https://twitter.com/yashwanth941v")!,
                    color: .black,
                    icon: .brand("XLogo")
                )

                LinkRow(
                    title: "Star on GitHub",
                    url: URL(string: "https://github.com/yashwanth941v/Typeboard")!,
                    color: Color(red: 0.14, green: 0.14, blue: 0.14),
                    icon: .brand("GitHubLogo")
                )

                LinkRow(
                    title: "Send Feedback",
                    url: URL(string: "mailto:yashwanth.941v@gmail.com")!,
                    color: .red,
                    icon: .system("envelope.fill")
                )
            } header: {
                Text("Connect")
            }

            Section {
                Text("Typeboard — type your clipboard with realistic typing, or get AI answers typed out for you.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("About Typeboard")
            }
        }
        .formStyle(.grouped)
    }

    // MARK: - AI Tab

    private var aiTab: some View {
        Form {
            Section {
                Toggle(isOn: Binding(
                    get: { settings.isAIEnabled },
                    set: { _ in showAIUnderDevelopment = true }
                )) {
                    HStack(spacing: 6) {
                        Text("Enable AI")
                        BetaPill()
                    }
                }
            } footer: {
                Text("AI is still under development and is disabled in this release. Coming soon.")
            }
            .alert("AI is still under development", isPresented: $showAIUnderDevelopment) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Local model downloads and cloud AI setup aren't ready yet. Typeboard v1 ships with typing features only — AI is coming in a future update.")
            }

            if settings.isAIEnabled {
                Section {
                    LabeledContent("Answer with AI") {
                        ShortcutRecorderView(name: .answerWithAI)
                    }
                } footer: {
                    Text("Copies the clipboard text to a local or cloud model, then types the answer.")
                }

                Section {
                    Picker("Provider", selection: $settings.aiProvider) {
                        ForEach(AIProvider.allCases) { provider in
                            Text(provider.displayName).tag(provider)
                        }
                    }

                    switch settings.aiProvider {
                    case .local:
                        Picker("Model", selection: $settings.aiModel) {
                            ForEach(OllamaModel.curated) { model in
                                Text(model.displayName).tag(model.id)
                            }
                        }

                        localStatsView
                        localStatusView

                    case .gemini:
                        Picker("Model", selection: $settings.geminiCloudModel) {
                            ForEach(GeminiModel.all) { model in
                                Text(model.displayName).tag(model.id)
                            }
                        }

                        geminiKeySection
                    }

                    aiStatusView
                } header: {
                    Text("AI Answer")
                }
            }
        }
        .formStyle(.grouped)
    }

    @ViewBuilder
    private var aiStatusView: some View {
        if settings.isAIThinking {
            HStack(spacing: 6) {
                ProgressView()
                    .scaleEffect(0.7)
                    .frame(width: 12, height: 12)
                Text(settings.aiStatusText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } else if settings.aiStatusText == "Done" {
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.caption)
                Text("Answer typed!")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Local Ollama

    private var localStatsView: some View {
        let model = OllamaModel.named(settings.aiModel)
        return HStack(spacing: 20) {
            StatBar(label: "Speed", value: model.speed)
            StatBar(label: "Brain", value: model.intelligence)
            StatBar(label: "Code", value: model.code)
            StatBar(label: "Weight", value: 6 - model.size)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
    }

    @ViewBuilder
    private var localStatusView: some View {
        if settings.isDownloading {
            VStack(alignment: .leading, spacing: 4) {
                ProgressView(value: settings.downloadProgress)
                    .progressViewStyle(.linear)
                Text(settings.downloadStatusText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } else if settings.isOllamaRunning, settings.isModelDownloaded(settings.aiModel) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.caption)
                Text("Ready")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Refresh") {
                    Task { await settings.checkOllamaStatus() }
                }
                .buttonStyle(.borderless)
                .font(.caption)

                if !isRemovingModel {
                    Button("Remove", role: .destructive) {
                        showRemoveConfirmation = true
                    }
                    .buttonStyle(.borderless)
                    .font(.caption)
                    .foregroundStyle(.red)
                } else {
                    ProgressView()
                        .scaleEffect(0.6)
                        .frame(width: 12, height: 12)
                }
            }
        } else {
            HStack {
                Image(systemName: "arrow.down.circle")
                    .font(.caption)
                    .foregroundStyle(.tint)
                Text(OllamaModel.named(settings.aiModel).sizeLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Download") {
                    Task { await settings.setupAndDownload() }
                }
                .font(.caption)
            }
        }
    }

    private func removeModel() async {
        isRemovingModel = true
        defer { isRemovingModel = false }

        do {
            try await OllamaClient.deleteModel(settings.aiModel)
            await settings.checkOllamaStatus()
        } catch {
            UserAlert.showWarning("Failed to remove model: \(error.localizedDescription)")
        }
    }

    // MARK: - Gemini Cloud

    @ViewBuilder
    private var geminiKeySection: some View {
        SecureField("API Key", text: $settings.geminiAPIKey)
            .textFieldStyle(.roundedBorder)
            .disableAutocorrection(true)
            .font(.caption)

        HStack {
            Button("Verify") {
                Task { await validateGeminiKey() }
            }
            .font(.caption)
            .disabled(settings.geminiAPIKey.isEmpty)

            if settings.geminiKeyStatus != .unknown {
                Text(settings.geminiKeyStatus.label)
                    .font(.caption)
                    .foregroundStyle(settings.geminiKeyStatus == .valid ? .green : .red)
            }
        }
    }

    private func validateGeminiKey() async {
        settings.geminiKeyStatus = .unknown
        do {
            try await GeminiClient.validateAPIKey(settings.geminiAPIKey)
            settings.geminiKeyStatus = .valid
        } catch {
            settings.geminiKeyStatus = .invalid
        }
    }
}

private struct BetaPill: View {
    var body: some View {
        Text("Beta")
            .font(.system(size: 9, weight: .medium))
            .foregroundStyle(.orange)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(.orange.opacity(0.15), in: Capsule())
            .overlay {
                Capsule()
                    .strokeBorder(.orange.opacity(0.4), lineWidth: 0.5)
            }
    }
}

private struct LinkRow: View {
    let title: String
    let url: URL
    let color: Color
    let icon: LinkIcon
    var containerSize: CGFloat = 22
    var iconSize: CGFloat = 13

    enum LinkIcon {
        case system(String)
        case brand(String)
    }

    var body: some View {
        Link(destination: url) {
            HStack(spacing: 10) {
                iconContainer

                Text(title)
                    .foregroundStyle(.primary)

                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var iconContainer: some View {
        ZStack {
            RoundedRectangle(cornerRadius: containerSize * 0.27, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [color, color.opacity(0.72)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            iconView
                .foregroundStyle(.white)
        }
        .frame(width: containerSize, height: containerSize)
        .overlay {
            RoundedRectangle(cornerRadius: containerSize * 0.27, style: .continuous)
                .strokeBorder(.white.opacity(0.18), lineWidth: 0.5)
        }
    }

    @ViewBuilder
    private var iconView: some View {
        switch icon {
        case .system(let name):
            Image(systemName: name)
                .font(.system(size: iconSize, weight: .semibold))
        case .brand(let name):
            Image(name)
                .resizable()
                .renderingMode(.template)
                .scaledToFit()
                .frame(width: iconSize, height: iconSize)
        }
    }
}

private struct StatBar: View {
    let label: String
    let value: Int

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 3) {
                ForEach(1...5, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(i <= value ? Color.accentColor : Color.gray.opacity(0.15))
                        .frame(width: 5, height: 18)
                }
            }

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    ContentView()
}
