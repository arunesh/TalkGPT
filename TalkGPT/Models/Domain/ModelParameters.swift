//
//  ModelParameters.swift
//  TalkGPT
//
//  Created by TalkGPT on 2025-11-19.
//  Phase 2 Implementation
//

import Foundation

/// Configuration parameters for LLM generation
struct ModelParameters: Codable, Equatable {
    var temperature: Float
    var maxTokens: Int
    var topP: Float
    var topK: Int
    var repeatPenalty: Float
    var contextSize: Int

    static let `default` = ModelParameters(
        temperature: 0.7,
        maxTokens: 2048,
        topP: 0.9,
        topK: 40,
        repeatPenalty: 1.1,
        contextSize: 4096
    )

    static let precise = ModelParameters(
        temperature: 0.3,
        maxTokens: 2048,
        topP: 0.85,
        topK: 30,
        repeatPenalty: 1.1,
        contextSize: 4096
    )

    static let creative = ModelParameters(
        temperature: 0.9,
        maxTokens: 2048,
        topP: 0.95,
        topK: 50,
        repeatPenalty: 1.05,
        contextSize: 4096
    )

    /// Validates parameters are within acceptable ranges
    func validated() -> ModelParameters {
        var params = self
        params.temperature = max(0.0, min(2.0, params.temperature))
        params.maxTokens = max(1, min(8192, params.maxTokens))
        params.topP = max(0.0, min(1.0, params.topP))
        params.topK = max(1, min(100, params.topK))
        params.repeatPenalty = max(1.0, min(2.0, params.repeatPenalty))
        params.contextSize = max(512, min(8192, params.contextSize))
        return params
    }
}

/// Information about the loaded model
struct ModelInfo: Codable {
    let name: String
    let version: String
    let size: String
    let contextLength: Int
    let quantization: String

    static let gemma2B = ModelInfo(
        name: "Gemma 2B",
        version: "1.0",
        size: "1.2 GB",
        contextLength: 4096,
        quantization: "Q4_K_M"
    )

    static let phi3Mini = ModelInfo(
        name: "Phi-3 Mini",
        version: "3.0",
        size: "2.0 GB",
        contextLength: 4096,
        quantization: "Q4_K_M"
    )

    static let none = ModelInfo(
        name: "No Model Loaded",
        version: "N/A",
        size: "0 GB",
        contextLength: 0,
        quantization: "N/A"
    )
}
