//
//  OpenAIBackend.swift
//  TalkGPT
//
//  Created by TalkGPT on 2025-11-19.
//  OpenAI API Integration
//

import Foundation

/// OpenAI API backend implementation
class OpenAIBackend: LLMBackend {
    let name = "OpenAI"

    private var apiKey: String = ""
    private var baseURL: String = "https://api.openai.com/v1"
    private var currentTask: URLSessionDataTask?

    var isConfigured: Bool {
        return !apiKey.isEmpty
    }

    var supportedModels: [String] {
        return ["gpt-4o", "gpt-4-turbo", "gpt-4", "gpt-3.5-turbo"]
    }

    func configure(apiKey: String, baseURL: String? = nil) throws {
        guard !apiKey.isEmpty else {
            throw LLMBackendError.invalidAPIKey
        }

        self.apiKey = apiKey
        if let baseURL = baseURL {
            self.baseURL = baseURL
        }
    }

    func generateStream(
        prompt: String,
        model: String,
        parameters: ModelParameters
    ) -> AsyncThrowingStream<String, Error> {
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    let url = URL(string: "\(self.baseURL)/chat/completions")!
                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.setValue("Bearer \(self.apiKey)", forHTTPHeaderField: "Authorization")
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

                    let requestBody = OpenAIChatRequest(
                        model: model,
                        messages: [OpenAIChatMessage(role: "user", content: prompt)],
                        temperature: parameters.temperature,
                        maxTokens: parameters.maxTokens,
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

                            if data == "[DONE]" {
                                break
                            }

                            if let jsonData = data.data(using: .utf8),
                               let chunk = try? JSONDecoder().decode(OpenAIStreamChunk.self, from: jsonData),
                               let content = chunk.choices.first?.delta.content {
                                continuation.yield(content)
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

// MARK: - OpenAI API Models

struct OpenAIChatRequest: Codable {
    let model: String
    let messages: [OpenAIChatMessage]
    let temperature: Float
    let maxTokens: Int
    let topP: Float
    let stream: Bool

    enum CodingKeys: String, CodingKey {
        case model, messages, temperature
        case maxTokens = "max_tokens"
        case topP = "top_p"
        case stream
    }
}

struct OpenAIChatMessage: Codable {
    let role: String
    let content: String
}

struct OpenAIStreamChunk: Codable {
    let id: String
    let object: String
    let created: Int
    let model: String
    let choices: [StreamChoice]

    struct StreamChoice: Codable {
        let index: Int
        let delta: StreamDelta
        let finishReason: String?

        enum CodingKeys: String, CodingKey {
            case index, delta
            case finishReason = "finish_reason"
        }
    }

    struct StreamDelta: Codable {
        let role: String?
        let content: String?
    }
}
