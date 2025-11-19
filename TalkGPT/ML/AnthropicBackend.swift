//
//  AnthropicBackend.swift
//  TalkGPT
//
//  Created by TalkGPT on 2025-11-19.
//  Anthropic Claude API Integration
//

import Foundation

/// Anthropic Claude API backend implementation
class AnthropicBackend: LLMBackend {
    let name = "Anthropic"

    private var apiKey: String = ""
    private let baseURL: String = "https://api.anthropic.com/v1"
    private var currentTask: URLSessionDataTask?

    var isConfigured: Bool {
        return !apiKey.isEmpty
    }

    var supportedModels: [String] {
        return [
            "claude-sonnet-4.5-20250929",
            "claude-3-5-sonnet-20241022",
            "claude-3-opus-20240229",
            "claude-3-sonnet-20240229",
            "claude-3-haiku-20240307"
        ]
    }

    func configure(apiKey: String, baseURL: String? = nil) throws {
        guard !apiKey.isEmpty else {
            throw LLMBackendError.invalidAPIKey
        }

        self.apiKey = apiKey
    }

    func generateStream(
        prompt: String,
        model: String,
        parameters: ModelParameters
    ) -> AsyncThrowingStream<String, Error> {
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    let url = URL(string: "\(self.baseURL)/messages")!
                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.setValue(self.apiKey, forHTTPHeaderField: "x-api-key")
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

                    let requestBody = AnthropicMessageRequest(
                        model: model,
                        messages: [AnthropicMessage(role: "user", content: prompt)],
                        maxTokens: parameters.maxTokens,
                        temperature: parameters.temperature,
                        topP: parameters.topP,
                        stream: true
                    )

                    request.httpBody = try JSONEncoder().encode(requestBody)

                    let (asyncBytes, response) = try await URLSession.shared.bytes(for: request)

                    guard let httpResponse = response as? HTTPURLResponse else {
                        throw LLMBackendError.invalidResponse
                    }

                    guard httpResponse.statusCode == 200 else {
                        throw LLMBackendError.apiError("HTTP \(httpResponse.statusCode)")
                    }

                    // Process streaming response
                    for try await line in asyncBytes.lines {
                        if line.hasPrefix("data: ") {
                            let data = line.dropFirst(6)

                            if let jsonData = data.data(using: .utf8),
                               let event = try? JSONDecoder().decode(AnthropicStreamEvent.self, from: jsonData) {

                                switch event.type {
                                case "content_block_delta":
                                    if let delta = event.delta,
                                       delta.type == "text_delta",
                                       let text = delta.text {
                                        continuation.yield(text)
                                    }

                                case "message_stop":
                                    break

                                default:
                                    break
                                }
                            }
                        }
                    }

                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    func cancelGeneration() {
        currentTask?.cancel()
        currentTask = nil
    }
}

// MARK: - Anthropic API Models

struct AnthropicMessageRequest: Codable {
    let model: String
    let messages: [AnthropicMessage]
    let maxTokens: Int
    let temperature: Float
    let topP: Float
    let stream: Bool

    enum CodingKeys: String, CodingKey {
        case model, messages, temperature, stream
        case maxTokens = "max_tokens"
        case topP = "top_p"
    }
}

struct AnthropicMessage: Codable {
    let role: String
    let content: String
}

struct AnthropicStreamEvent: Codable {
    let type: String
    let delta: AnthropicDelta?
    let index: Int?

    struct AnthropicDelta: Codable {
        let type: String
        let text: String?
    }
}
