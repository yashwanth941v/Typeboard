import Foundation

enum OllamaError: LocalizedError {
    case notRunning
    case modelNotFound
    case pullFailed(String)
    case generateFailed(String)
    case setupFailed(String)
    case deleteFailed(String)

    var errorDescription: String? {
        switch self {
        case .notRunning: return "Ollama isn't running. Open Ollama from your Applications folder."
        case .modelNotFound: return "Selected model isn't downloaded yet."
        case .pullFailed(let msg): return msg
        case .generateFailed(let msg): return msg
        case .setupFailed(let msg): return msg
        case .deleteFailed(let msg): return msg
        }
    }
}

// MARK: - AI Provider

enum AIProvider: String, CaseIterable, Identifiable {
    case local
    case gemini

    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .local: return "Local (Ollama)"
        case .gemini: return "Gemini"
        }
    }
}

// MARK: - Local Models

struct OllamaModel: Identifiable, Hashable {
    let id: String
    let displayName: String
    let sizeLabel: String
    let speed: Int
    let intelligence: Int
    let code: Int
    let size: Int

    static let curated: [OllamaModel] = [
        OllamaModel(id: "qwen2.5-coder:7b", displayName: "Qwen 2.5 Coder 7B", sizeLabel: "~4.0 GB",
                    speed: 4, intelligence: 4, code: 5, size: 2),
        OllamaModel(id: "llama3.2:3b", displayName: "Llama 3.2 3B", sizeLabel: "~2.0 GB",
                    speed: 5, intelligence: 3, code: 3, size: 4),
        OllamaModel(id: "llama3.1:8b", displayName: "Llama 3.1 8B", sizeLabel: "~4.7 GB",
                    speed: 3, intelligence: 5, code: 4, size: 2),
        OllamaModel(id: "gemma2:2b", displayName: "Gemma 2 2B", sizeLabel: "~1.5 GB",
                    speed: 5, intelligence: 2, code: 2, size: 5),
        OllamaModel(id: "phi3.5:3.8b", displayName: "Phi-3.5 3.8B", sizeLabel: "~2.3 GB",
                    speed: 4, intelligence: 4, code: 4, size: 4),
    ]

    static func named(_ id: String) -> OllamaModel {
        curated.first { $0.id == id } ?? curated[0]
    }
}

// MARK: - Cloud Models

struct GeminiModel: Identifiable, Hashable {
    let id: String
    let displayName: String

    static let all: [GeminiModel] = [
        GeminiModel(id: "gemini-2.0-flash", displayName: "Gemini 2.0 Flash"),
        GeminiModel(id: "gemini-2.0-flash-lite", displayName: "Gemini 2.0 Flash Lite"),
        GeminiModel(id: "gemini-1.5-flash", displayName: "Gemini 1.5 Flash"),
        GeminiModel(id: "gemini-1.5-flash-8b", displayName: "Gemini 1.5 Flash 8B"),
        GeminiModel(id: "gemini-1.5-pro", displayName: "Gemini 1.5 Pro"),
    ]

    static func named(_ id: String) -> GeminiModel {
        all.first { $0.id == id } ?? all[0]
    }
}

// MARK: - Ollama Client

enum OllamaClient {
    private static let baseURL = URL(string: "http://localhost:11434")!

    static func checkRunning() async -> Bool {
        var request = URLRequest(url: baseURL.appendingPathComponent("/api/tags"))
        request.timeoutInterval = 2
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }

    static func listDownloadedModels() async throws -> [String] {
        let url = baseURL.appendingPathComponent("/api/tags")
        let (data, _) = try await URLSession.shared.data(from: url)

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let models = json["models"] as? [[String: Any]] else {
            return []
        }

        return models.compactMap { $0["name"] as? String }
    }

    static func pullModel(_ name: String, progress: @escaping (Double) -> Void) async throws {
        let url = baseURL.appendingPathComponent("/api/pull")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["name": name, "stream": true])

        let (bytes, response) = try await URLSession.shared.bytes(for: request)

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw OllamaError.pullFailed("Failed to start download.")
        }

        var progressMap: [String: (completed: Int64, total: Int64)] = [:]

        for try await line in bytes.lines {
            guard let data = line.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                continue
            }

            if let status = json["status"] as? String {
                if status == "success" {
                    progress(1.0)
                    return
                }

                if let digest = json["digest"] as? String,
                   let total = json["total"] as? Int64,
                   let completed = json["completed"] as? Int64 {
                    progressMap[digest] = (completed, total)
                }
            }

            let totalTotal = progressMap.values.reduce(0) { $0 + $1.total }
            let totalCompleted = progressMap.values.reduce(0) { $0 + $1.completed }
            let pct = totalTotal > 0 ? Double(totalCompleted) / Double(totalTotal) : 0
            progress(min(pct, 0.99))
        }
    }

    static func deleteModel(_ name: String) async throws {
        let url = baseURL.appendingPathComponent("/api/delete")
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["name": name])

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw OllamaError.deleteFailed("Failed to delete model.")
        }
    }

    static func generate(prompt: String, model: String) async throws -> String {
        let url = baseURL.appendingPathComponent("/api/generate")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "model": model,
            "prompt": prompt,
            "stream": false,
            "options": [
                "temperature": 0.2,
                "num_predict": 2048,
            ],
        ])

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw OllamaError.generateFailed("Ollama request failed.")
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let text = json["response"] as? String else {
            throw OllamaError.generateFailed("Unexpected response from Ollama.")
        }

        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Gemini Client

enum GeminiClient {
    private static let endpoint = "https://generativelanguage.googleapis.com/v1beta/models"

    private static func request(_ path: String, apiKey: String) -> URLRequest {
        let url = URL(string: "\(endpoint)\(path)")!
        var req = URLRequest(url: url)
        req.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
        return req
    }

    static func validateAPIKey(_ apiKey: String) async throws {
        var req = request("/", apiKey: apiKey)
        req.httpMethod = "GET"

        let (_, response) = try await URLSession.shared.data(for: req)

        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            throw OllamaError.generateFailed("Invalid API key (\(http.statusCode)).")
        }
    }

    static func generate(question: String, model: String, apiKey: String) async throws -> String {
        let prompt = """
        The user copied the following text. Answer it directly and concisely.

        Rules:
        - If it asks for code, respond with only the code. No markdown fences, no explanation.
        - Otherwise give a direct, concise answer.
        - If the text is empty, unclear, or not something you can answer, respond with exactly: NO_ANSWER

        Copied text:
        \(question)
        """

        var req = request("/\(model):generateContent", apiKey: apiKey)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: [
            "contents": [
                ["parts": [["text": prompt]]]
            ]
        ])

        let (data, response) = try await URLSession.shared.data(for: req)

        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw OllamaError.generateFailed("Gemini request failed (\(http.statusCode)): \(body)")
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let first = candidates.first,
              let content = first["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let text = parts.first?["text"] as? String else {
            throw OllamaError.generateFailed("Unexpected response from Gemini.")
        }

        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
