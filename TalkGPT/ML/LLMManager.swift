//
//  LLMManager.swift
//  TalkGPT
//
//  Created by TalkGPT on 2025-11-19.
//  Updated with Cloud Backend Support
//

import Foundation

/// Protocol for LLM inference
protocol LLMManagerProtocol {
    var isModelLoaded: Bool { get }
    var modelInfo: ModelInfo { get }

    func loadModel(at path: URL) async throws
    func unloadModel() async
    func generate(prompt: String, parameters: ModelParameters) -> AsyncThrowingStream<String, Error>
    func stopGeneration()
}

/// Manages LLM model loading and inference
/// Supports both cloud backends (OpenAI, Anthropic) and local models (llama.cpp)
class LLMManager: LLMManagerProtocol {
    static let shared = LLMManager()

    private let backendManager = LLMBackendManager.shared

    var isModelLoaded: Bool {
        return backendManager.isConfigured
    }

    var modelInfo: ModelInfo {
        return backendManager.currentModelInfo
    }

    private init() {}

    // MARK: - Model Management

    /// Loads a model from the given path (for local models - future feature)
    /// Currently using cloud backends
    func loadModel(at path: URL) async throws {
        // For local model loading with llama.cpp in future
        throw LLMError.modelLoadFailed("Local model loading not yet implemented. Use cloud backends in Settings.")
    }

    /// Unloads the current model from memory
    func unloadModel() async {
        // For cloud backends, this is handled by configuration
    }

    // MARK: - Text Generation

    /// Generates text based on the prompt with streaming output
    /// Uses configured cloud backend (OpenAI or Anthropic)
    func generate(prompt: String, parameters: ModelParameters) -> AsyncThrowingStream<String, Error> {
        return backendManager.generateStream(prompt: prompt, parameters: parameters)
    }

    /// Stops the current generation
    func stopGeneration() {
        backendManager.cancelGeneration()
    }

    // MARK: - Configuration

    /// Gets the current backend configuration
    func getConfiguration() -> LLMConfiguration {
        return backendManager.configuration
    }

    /// Updates the backend configuration
    func updateConfiguration(_ config: LLMConfiguration) {
        backendManager.updateConfiguration(config)
    }
}

// MARK: - Errors

enum LLMError: LocalizedError {
    case modelNotLoaded
    case modelAlreadyLoaded
    case modelLoadFailed(String)
    case generationInProgress
    case generationFailed(String)
    case invalidParameters
    case outOfMemory

    var errorDescription: String? {
        switch self {
        case .modelNotLoaded:
            return "No model is currently loaded. Please load a model first."
        case .modelAlreadyLoaded:
            return "A model is already loaded. Unload it before loading another."
        case .modelLoadFailed(let reason):
            return "Failed to load model: \(reason)"
        case .generationInProgress:
            return "Text generation is already in progress."
        case .generationFailed(let reason):
            return "Text generation failed: \(reason)"
        case .invalidParameters:
            return "Invalid generation parameters provided."
        case .outOfMemory:
            return "Not enough memory to load the model."
        }
    }
}
