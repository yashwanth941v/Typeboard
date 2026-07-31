import AppKit

@MainActor
final class AIManager {
    static let shared = AIManager()

    private var isRunning = false

    private init() {}

    func trigger() {
        guard !isRunning else { return }

        let settings = AppSettings.shared
        guard settings.isAIEnabled else { return }

        guard let text = ClipboardManager.shared.currentText()?.trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty else {
            UserAlert.showWarning("Copy a question or prompt first.")
            return
        }

        let speed = settings.typingSpeed

        isRunning = true
        settings.isAIThinking = true
        settings.aiStatusText = "Thinking…"

        Task {
            defer {
                isRunning = false
                settings.isAIThinking = false
            }

            do {
                let answer: String

                switch settings.aiProvider {
                case .local:
                    guard settings.isOllamaRunning else {
                        UserAlert.showWarning("Ollama isn't running. Open Ollama from your Applications folder.")
                        return
                    }

                    let prompt = """
                    The user copied the following text. Answer it directly and concisely.

                    Rules:
                    - If it asks for code, respond with only the code. No markdown fences, no explanation.
                    - Otherwise give a direct, concise answer.
                    - If the text is empty, unclear, or not something you can answer, respond with exactly: NO_ANSWER

                    Copied text:
                    \(text)
                    """

                    settings.aiStatusText = "Contacting local model…"
                    answer = try await OllamaClient.generate(prompt: prompt, model: settings.aiModel)

                case .gemini:
                    guard !settings.geminiAPIKey.isEmpty else {
                        UserAlert.showWarning("Set your Gemini API key in Settings first.")
                        return
                    }

                    settings.aiStatusText = "Contacting Gemini…"
                    answer = try await GeminiClient.generate(
                        question: text,
                        model: settings.geminiCloudModel,
                        apiKey: settings.geminiAPIKey
                    )
                }

                guard answer != "NO_ANSWER", !answer.isEmpty else {
                    UserAlert.showWarning("The model couldn't answer that. Try rephrasing.")
                    return
                }

                settings.aiStatusText = "Typing answer…"
                TypingController.shared.startTypingFromHotkey(answer, speed: speed)
                settings.aiStatusText = "Done"
            } catch {
                settings.aiStatusText = "Error"
                UserAlert.showWarning(error.localizedDescription)
            }
        }
    }
}
