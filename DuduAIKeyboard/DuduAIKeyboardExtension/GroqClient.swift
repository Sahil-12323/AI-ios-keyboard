import Foundation

// ─── Groq API Client ─────────────────────────────────────────────────────────
// Mirrors the Android OpenAiClient but in Swift with async/await + streaming

actor GroqClient {

    // ⚠️  Replace with your actual Groq API key
    // In production: store in Keychain or fetch from your own backend
    static let apiKey = "YOUR_GROQ_API_KEY_HERE"

    static let endpoint = URL(string: "https://api.groq.com/openai/v1/chat/completions")!

    static let systemPrompt = """
    You are an AI writing assistant embedded inside an iOS keyboard.
    The user typed a prompt describing a message they want to send.
    Reply with ONLY the final message text — no preamble, no quotes, no labels, no explanations.
    Match tone exactly: grief=heartfelt, birthday=joyful, apology=sincere, professional=formal, casual=friendly.
    1-5 sentences maximum. Be concise and natural.
    """

    // ── Streaming generation ──────────────────────────────────────────────────
    static func stream(
        prompt: String,
        tone: String = "",
        history: [(role: String, content: String)] = [],
        onToken: @escaping (String) -> Void,
        onDone: @escaping () -> Void,
        onError: @escaping (String) -> Void
    ) {
        let systemContent = tone.isEmpty ? systemPrompt : "\(systemPrompt)\nTone override: write in a \(tone) style."
        let model = prompt.count < 120 ? "llama-3.1-8b-instant" : "llama-3.3-70b-versatile"

        var messages: [[String: String]] = [["role": "system", "content": systemContent]]
        for msg in history.suffix(6) {
            messages.append(["role": msg.role, "content": msg.content])
        }
        messages.append(["role": "user", "content": prompt])

        let body: [String: Any] = [
            "model": model,
            "max_tokens": 300,
            "stream": true,
            "temperature": 0.7,
            "messages": messages
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            onError("Failed to build request"); return
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        request.timeoutInterval = 90

        let task = URLSession.shared.dataTask(with: request)
        let delegate = StreamDelegate(onToken: onToken, onDone: onDone, onError: onError)

        // Use a custom URLSession with delegate for streaming
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config, delegate: delegate, delegateQueue: nil)
        session.dataTask(with: request).resume()
        _ = delegate // keep alive
    }

    // ── Quick suggestions (non-streaming, fast) ───────────────────────────────
    static func getSuggestions(
        context: String,
        completion: @escaping ([String]) -> Void
    ) {
        let body: [String: Any] = [
            "model": "llama-3.1-8b-instant",
            "max_tokens": 120,
            "temperature": 0.8,
            "messages": [
                ["role": "system", "content": """
                    Generate exactly 3 short message continuation suggestions (5-8 words each).
                    The user is typing: \"\(context)\"
                    Return ONLY a JSON array of 3 strings. Example: ["suggestion 1","suggestion 2","suggestion 3"]
                    No explanation. Just the JSON array.
                    """],
                ["role": "user", "content": context.isEmpty ? "Hello" : context]
            ]
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            completion([]); return
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 10

        URLSession.shared.dataTask(with: request) { data, _, error in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let choices = json["choices"] as? [[String: Any]],
                  let message = choices.first?["message"] as? [String: Any],
                  let content = message["content"] as? String else {
                DispatchQueue.main.async { completion([]) }
                return
            }
            // Parse JSON array from response
            let cleaned = content.trimmingCharacters(in: .whitespacesAndNewlines)
            if let arrData = cleaned.data(using: .utf8),
               let arr = try? JSONSerialization.jsonObject(with: arrData) as? [String] {
                DispatchQueue.main.async { completion(arr) }
            } else {
                DispatchQueue.main.async { completion([]) }
            }
        }.resume()
    }
}

// ─── SSE Stream Delegate ──────────────────────────────────────────────────────
class StreamDelegate: NSObject, URLSessionDataDelegate {
    let onToken: (String) -> Void
    let onDone: () -> Void
    let onError: (String) -> Void
    private var buffer = ""

    init(onToken: @escaping (String) -> Void, onDone: @escaping () -> Void, onError: @escaping (String) -> Void) {
        self.onToken = onToken
        self.onDone = onDone
        self.onError = onError
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard let text = String(data: data, encoding: .utf8) else { return }
        buffer += text
        processBuffer()
    }

    private func processBuffer() {
        let lines = buffer.components(separatedBy: "\n")
        buffer = lines.last ?? ""
        for line in lines.dropLast() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard trimmed.hasPrefix("data:") else { continue }
            let payload = trimmed.dropFirst(5).trimmingCharacters(in: .whitespaces)
            if payload == "[DONE]" {
                DispatchQueue.main.async { self.onDone() }
                continue
            }
            if let data = payload.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let choices = json["choices"] as? [[String: Any]],
               let delta = choices.first?["delta"] as? [String: Any],
               let content = delta["content"] as? String,
               !content.isEmpty {
                DispatchQueue.main.async { self.onToken(content) }
            }
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            DispatchQueue.main.async { self.onError(error.localizedDescription) }
        }
    }
}
