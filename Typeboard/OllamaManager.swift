import Foundation

@MainActor
final class OllamaManager {
    static let shared = OllamaManager()

    private var serverProcess: Process?
    private let ollamaDir: URL

    private init() {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        ollamaDir = support.appendingPathComponent("Typeboard/ollama", isDirectory: true)
    }

    var binaryURL: URL {
        ollamaDir.appendingPathComponent("ollama")
    }

    var isInstalled: Bool {
        FileManager.default.fileExists(atPath: binaryURL.path)
    }

    func downloadBinary(progress: @escaping (Double) -> Void) async throws {
        try FileManager.default.createDirectory(at: ollamaDir, withIntermediateDirectories: true)

        guard let url = URL(string: "https://github.com/ollama/ollama/releases/latest/download/Ollama-darwin.zip") else {
            throw OllamaError.setupFailed("Invalid download URL.")
        }

        progress(0)

        let (downloadURL, _) = try await URLSession.shared.download(from: url)
        let zipURL = ollamaDir.appendingPathComponent("Ollama-darwin.zip")

        try FileManager.default.moveItem(at: downloadURL, to: zipURL)

        progress(0.3)

        let extractDir = ollamaDir.appendingPathComponent("extract")
        try FileManager.default.createDirectory(at: extractDir, withIntermediateDirectories: true)

        let ditto = Process()
        ditto.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
        ditto.arguments = ["-x", "-k", zipURL.path, extractDir.path]
        try ditto.run()
        ditto.waitUntilExit()

        progress(0.5)

        let appBundle = extractDir.appendingPathComponent("Ollama.app")
        let binaryInApp = appBundle.appendingPathComponent("Contents/Resources/ollama")

        if FileManager.default.fileExists(atPath: binaryInApp.path) {
            try FileManager.default.moveItem(at: binaryInApp, to: binaryURL)
        } else {
            throw OllamaError.setupFailed("Could not find ollama binary in downloaded package.")
        }

        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: binaryURL.path)

        try? FileManager.default.removeItem(at: zipURL)
        try? FileManager.default.removeItem(at: extractDir)

        progress(0.6)
    }

    func startServer() throws {
        guard serverProcess == nil else { return }

        let modelsDir = ollamaDir.appendingPathComponent("models")
        try FileManager.default.createDirectory(at: modelsDir, withIntermediateDirectories: true)

        let process = Process()
        process.executableURL = binaryURL
        process.arguments = ["serve"]
        process.environment = [
            "OLLAMA_MODELS": modelsDir.path,
            "HOME": NSHomeDirectory(),
        ]

        try process.run()
        serverProcess = process
    }

    func waitForServer() async throws {
        for _ in 0..<60 {
            if await OllamaClient.checkRunning() { return }
            try await Task.sleep(nanoseconds: 1_000_000_000)
        }
        throw OllamaError.setupFailed("Ollama server didn't start within 60 seconds.")
    }

    func stopServer() {
        serverProcess?.terminate()
        serverProcess = nil
    }

    func cleanupTempFiles() {
        let fm = FileManager.default
        try? fm.removeItem(at: ollamaDir.appendingPathComponent("Ollama-darwin.zip"))
        try? fm.removeItem(at: ollamaDir.appendingPathComponent("extract"))
    }
}
