//
//  LLMBackend.swift
//  TalkGPT
//
//  Created by TalkGPT on 2025-11-19.
//  Cloud LLM Backend Integration
//

import Foundation

/// Protocol for LLM backend implementations
protocol LLMBackend {
    var name: String { get }
    var isConfigured: Bool { get }
    var supportedModels: [String] { get }

    func configure(apiKey: String, baseURL: String?) throws
    func generateStream(
        prompt: String,
        model: String,
        parameters: ModelParameters
    ) -> AsyncThrowingStream<String, Error>
    func cancelGeneration()
}

/// Configuration for LLM backends
struct LLMConfiguration: Codable {
    var selectedBackend: BackendType
    var openAIAPIKey: String
    var openAIBaseURL: String?
    var anthropicAPIKey: String
    var selectedModel: String

    enum BackendType: String, Codable, CaseIterable {
        case openAI = "OpenAI"
        case anthropic = "Anthropic"
        case custom = "Custom"

        var displayName: String {
            switch self {
            case .openAI: return "OpenAI (GPT)"
            case .anthropic: return "Anthropic (Claude)"
            case .custom: return "Custom (OpenAI-compatible)"
            }
        }

        var defaultModels: [String] {
            switch self {
            case .openAI:
                return ["gpt-4o", "gpt-4-turbo", "gpt-3.5-turbo"]
            case .anthropic:
                return ["claude-sonnet-4.5-20250929", "claude-3-5-sonnet-20241022", "claude-3-opus-20240229"]
            case .custom:
                return []
            }
        }
    }

    static let `default` = LLMConfiguration(
        selectedBackend: .openAI,
        openAIAPIKey: "",
        openAIBaseURL: nil,
        anthropicAPIKey: "",
        selectedModel: "gpt-4o"
    )

    // Load from environment variables
    static func fromEnvironment() -> LLMConfiguration {
        var config = LLMConfiguration.default

        // Read from environment variables
        if let openAIKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] {
            config.openAIAPIKey = openAIKey
        }

        if let anthropicKey = ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"] {
            config.anthropicAPIKey = anthropicKey
        }

        if let baseURL = ProcessInfo.processInfo.environment["OPENAI_BASE_URL"] {
            config.openAIBaseURL = baseURL
        }

        return config
    }

    // Persistence
    private static let configKey = "llm_configuration"

    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Self.configKey)
        }
    }

    static func load() -> LLMConfiguration {
        guard let data = UserDefaults.standard.data(forKey: configKey),
              let config = try? JSONDecoder().decode(LLMConfiguration.self, from: data) else {
            // Try loading from environment if no saved config
            return fromEnvironment()
        }

        // Merge with environment variables (env vars take precedence)
        var mergedConfig = config
        let envConfig = fromEnvironment()

        if !envConfig.openAIAPIKey.isEmpty {
            mergedConfig.openAIAPIKey = envConfig.openAIAPIKey
        }
        if !envConfig.anthropicAPIKey.isEmpty {
            mergedConfig.anthropicAPIKey = envConfig.anthropicAPIKey
        }
        if let baseURL = envConfig.openAIBaseURL {
            mergedConfig.openAIBaseURL = baseURL
        }

        return mergedConfig
    }
}

/// Manager for LLM backends
class LLMBackendManager {
    static let shared = LLMBackendManager()

    private(set) var currentBackend: LLMBackend?
    private(set) var configuration: LLMConfiguration

    private var openAIBackend: OpenAIBackend?
    private var anthropicBackend: AnthropicBackend?

    private init() {
        configuration = LLMConfiguration.load()
        setupBackend()
    }

    func updateConfiguration(_ config: LLMConfiguration) {
        configuration = config
        config.save()
        setupBackend()
    }

    private func setupBackend() {
        do {
            switch configuration.selectedBackend {
            case .openAI:
                if openAIBackend == nil {
                    openAIBackend = OpenAIBackend()
                }
                try openAIBackend?.configure(
                    apiKey: configuration.openAIAPIKey,
                    baseURL: configuration.openAIBaseURL
                )
                currentBackend = openAIBackend

            case .anthropic:
                if anthropicBackend == nil {
                    anthropicBackend = AnthropicBackend()
                }
                try anthropicBackend?.configure(
                    apiKey: configuration.anthropicAPIKey,
                    baseURL: nil
                )
                currentBackend = anthropicBackend

            case .custom:
                // Custom OpenAI-compatible backend
                if openAIBackend == nil {
                    openAIBackend = OpenAIBackend()
                }
                try openAIBackend?.configure(
                    apiKey: configuration.openAIAPIKey,
                    baseURL: configuration.openAIBaseURL
                )
                currentBackend = openAIBackend
            }
        } catch {
            print("Failed to configure backend: \(error)")
            currentBackend = nil
        }
    }

    func generateStream(
        prompt: String,
        parameters: ModelParameters
    ) -> AsyncThrowingStream<String, Error> {
        guard let backend = currentBackend else {
            return AsyncThrowingStream { continuation in
                continuation.finish(throwing: LLMBackendError.notConfigured)
            }
        }

        return backend.generateStream(
            prompt: prompt,
            model: configuration.selectedModel,
            parameters: parameters
        )
    }

    func cancelGeneration() {
        currentBackend?.cancelGeneration()
    }

    var isConfigured: Bool {
        return currentBackend?.isConfigured ?? false
    }

    var currentModelInfo: ModelInfo {
        guard isConfigured else {
            return .none
        }

        return ModelInfo(
            name: configuration.selectedModel,
            version: configuration.selectedBackend.displayName,
            size: "Cloud API",
            contextLength: contextLengthForModel(configuration.selectedModel),
            quantization: "N/A"
        )
    }

    private func contextLengthForModel(_ model: String) -> Int {
        if model.contains("gpt-4") {
            return 128000
        } else if model.contains("claude-3") || model.contains("claude-sonnet") {
            return 200000
        } else {
            return 4096
        }
    }
}

// MARK: - Errors

enum LLMBackendError: LocalizedError {
    case notConfigured
    case invalidAPIKey
    case networkError(String)
    case apiError(String)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "LLM backend is not configured. Please add your API key in Settings."
        case .invalidAPIKey:
            return "Invalid API key. Please check your configuration."
        case .networkError(let message):
            return "Network error: \(message)"
        case .apiError(let message):
            return "API error: \(message)"
        case .invalidResponse:
            return "Invalid response from API"
        }
    }
}
