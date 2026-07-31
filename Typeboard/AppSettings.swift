//
//  AppSettings.swift
//  Typeboard
//

import Combine
import Foundation

enum GeminiAPIKeyStatus: String {
    case unknown
    case valid
    case invalid

    var label: String {
        switch self {
        case .unknown: return ""
        case .valid: return "✓ Key is valid"
        case .invalid: return "✗ Invalid key"
        }
    }
}

enum TypingSpeed: String, CaseIterable, Identifiable {
    case instant, auto, fast, medium, slow

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .instant: return "Instant"
        case .auto: return "Auto"
        case .fast: return "Fast"
        case .medium: return "Medium"
        case .slow: return "Slow"
        }
    }

    var footerDescription: String {
        let controls = "Esc cancels mid-type; Cmd+Z right after undoes the whole block."
        switch self {
        case .instant:
            return "Pastes clipboard text with no visible animation. \(controls)"
        case .auto:
            return "Paces typing by content size — shorter text types letter-by-letter, longer text types in larger chunks. \(controls)"
        case .fast:
            return "Types quickly and ramps up toward the end so long text doesn't keep you waiting. \(controls)"
        case .medium:
            return "Types at a moderate, human-like pace and speeds up as it finishes. \(controls)"
        case .slow:
            return "Types slowly at first, then accelerates toward the end so you aren't waiting on the last stretch. \(controls)"
        }
    }
}

final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @Published var typingSpeed: TypingSpeed {
        didSet {
            UserDefaults.standard.set(typingSpeed.rawValue, forKey: "typingSpeed")
        }
    }

    @Published var aiModel: String {
        didSet {
            UserDefaults.standard.set(aiModel, forKey: "aiModel")
        }
    }

    @Published var aiProvider: AIProvider {
        didSet {
            UserDefaults.standard.set(aiProvider.rawValue, forKey: "aiProvider")
        }
    }

    @Published var geminiCloudModel: String {
        didSet {
            UserDefaults.standard.set(geminiCloudModel, forKey: "geminiCloudModel")
        }
    }

    @Published var geminiAPIKey: String {
        didSet {
            KeychainStore.save(geminiAPIKey, account: "geminiAPIKey")
        }
    }

    @Published var geminiKeyStatus: GeminiAPIKeyStatus = .unknown

    @Published var isOllamaRunning = false
    @Published var downloadedModels: [String] = []
    @Published var isDownloading = false
    @Published var downloadProgress: Double = 0
    @Published var downloadStatusText = ""

    @Published var isAIThinking = false
    @Published var aiStatusText = ""

    @Published var isTypingEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isTypingEnabled, forKey: "isTypingEnabled")
        }
    }

    @Published var isAIEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isAIEnabled, forKey: "isAIEnabled")
        }
    }

    private init() {
        let storedSpeed = UserDefaults.standard.string(forKey: "typingSpeed") ?? ""

        if storedSpeed == "normal" {
            typingSpeed = .medium
        } else if let speed = TypingSpeed(rawValue: storedSpeed) {
            typingSpeed = speed
        } else if UserDefaults.standard.object(forKey: "instant") as? Bool == true
                    || (UserDefaults.standard.object(forKey: "instant") == nil
                        && !UserDefaults.standard.bool(forKey: "animateTyping")) {
            typingSpeed = .instant
        } else {
            typingSpeed = .auto
        }

        aiModel = UserDefaults.standard.string(forKey: "aiModel") ?? OllamaModel.curated[0].id

        let savedKey = KeychainStore.load(account: "geminiAPIKey") ?? ""

        let storedProvider = UserDefaults.standard.string(forKey: "aiProvider")
        aiProvider = AIProvider(rawValue: storedProvider ?? "") ?? (savedKey.isEmpty ? .local : .gemini)

        geminiCloudModel = UserDefaults.standard.string(forKey: "geminiCloudModel") ?? GeminiModel.all[0].id

        geminiAPIKey = savedKey

        isTypingEnabled = UserDefaults.standard.object(forKey: "isTypingEnabled") as? Bool ?? true

        isAIEnabled = false
    }

    func checkOllamaStatus() async {
        isOllamaRunning = await OllamaClient.checkRunning()
        if isOllamaRunning {
            downloadedModels = (try? await OllamaClient.listDownloadedModels()) ?? []
        } else {
            downloadedModels = []
        }
    }

    func isModelDownloaded(_ name: String) -> Bool {
        downloadedModels.contains { $0.hasPrefix(name) }
    }

    func setupAndDownload() async {
        let model = aiModel
        guard !isDownloading else { return }

        isDownloading = true
        downloadProgress = 0

        if !OllamaManager.shared.isInstalled {
            downloadStatusText = "Downloading Ollama…"
            do {
                try await OllamaManager.shared.downloadBinary { [weak self] pct in
                    Task { @MainActor in self?.downloadProgress = pct }
                }
            } catch {
                downloadStatusText = "Failed: \(error.localizedDescription)"
                isDownloading = false
                return
            }
        }

        downloadStatusText = "Starting server…"
        downloadProgress = 0.6
        do {
            try OllamaManager.shared.startServer()
            try await OllamaManager.shared.waitForServer()
        } catch {
            downloadStatusText = "Failed: \(error.localizedDescription)"
            isDownloading = false
            return
        }

        downloadStatusText = "Downloading \(model)…"
        downloadProgress = 0.7
        do {
            try await OllamaClient.pullModel(model) { [weak self] pct in
                Task { @MainActor in
                    let adjusted = 0.7 + pct * 0.3
                    self?.downloadProgress = adjusted
                }
            }
        } catch {
            downloadStatusText = "Failed: \(error.localizedDescription)"
            isDownloading = false
            return
        }

        downloadStatusText = "Ready"
        downloadProgress = 1
        isOllamaRunning = true
        downloadedModels = (try? await OllamaClient.listDownloadedModels()) ?? []
        isDownloading = false
    }
}
