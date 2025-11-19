//
//  EmbeddingManager.swift
//  TalkGPT
//
//  Created by TalkGPT on 2025-11-19.
//  Phase 4 Implementation - Vector Search
//

import Foundation
import NaturalLanguage

/// Manager for generating text embeddings for semantic search
class EmbeddingManager {
    static let shared = EmbeddingManager()

    private let embeddingModel: NLEmbedding?
    private let dimensions = 300 // Word embedding dimensions

    private init() {
        // Use Apple's NLEmbedding for word-level embeddings
        // This is lightweight and available on-device
        embeddingModel = NLEmbedding.wordEmbedding(for: .english)
    }

    // MARK: - Public Methods

    /// Generates an embedding vector for the given text
    /// - Parameter text: The input text to embed
    /// - Returns: A normalized embedding vector, or nil if embedding fails
    func embed(text: String) -> [Float]? {
        guard !text.isEmpty else { return nil }

        // Tokenize and clean text
        let tokens = tokenize(text: text)
        guard !tokens.isEmpty else { return nil }

        // Generate embeddings for each token
        var embeddings: [[Double]] = []

        for token in tokens {
            if let vector = embeddingModel?.vector(for: token) {
                embeddings.append(vector)
            }
        }

        guard !embeddings.isEmpty else { return nil }

        // Average pooling: compute mean of all token embeddings
        let averaged = averagePooling(embeddings: embeddings)

        // Normalize the vector
        let normalized = normalize(vector: averaged)

        // Convert to Float for consistency
        return normalized.map { Float($0) }
    }

    /// Generates embeddings for multiple texts
    /// - Parameter texts: Array of texts to embed
    /// - Returns: Array of embedding vectors
    func embedBatch(texts: [String]) async -> [TextEmbedding] {
        return await withTaskGroup(of: (Int, [Float]?).self) { group in
            for (index, text) in texts.enumerated() {
                group.addTask {
                    return (index, self.embed(text: text))
                }
            }

            var results: [TextEmbedding] = []
            for await (index, embedding) in group {
                if let embedding = embedding {
                    results.append(TextEmbedding(
                        id: UUID(),
                        text: texts[index],
                        vector: embedding,
                        createdAt: Date()
                    ))
                }
            }

            return results.sorted { $0.text.count > $1.text.count }
        }
    }

    /// Calculates cosine similarity between two embedding vectors
    /// - Parameters:
    ///   - vector1: First embedding vector
    ///   - vector2: Second embedding vector
    /// - Returns: Similarity score between 0 and 1 (1 = identical)
    func cosineSimilarity(vector1: [Float], vector2: [Float]) -> Float {
        guard vector1.count == vector2.count else { return 0.0 }

        let dotProduct = zip(vector1, vector2).reduce(0.0) { $0 + ($1.0 * $1.1) }
        let magnitude1 = sqrt(vector1.reduce(0.0) { $0 + ($1 * $1) })
        let magnitude2 = sqrt(vector2.reduce(0.0) { $0 + ($1 * $1) })

        guard magnitude1 > 0 && magnitude2 > 0 else { return 0.0 }

        return dotProduct / (magnitude1 * magnitude2)
    }

    // MARK: - Private Helpers

    private func tokenize(text: String) -> [String] {
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = text.lowercased()

        var tokens: [String] = []
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { tokenRange, _ in
            let token = String(text[tokenRange])
            // Filter out punctuation and very short tokens
            if token.count > 2 && token.rangeOfCharacter(from: .letters) != nil {
                tokens.append(token)
            }
            return true
        }

        return tokens
    }

    private func averagePooling(embeddings: [[Double]]) -> [Double] {
        guard !embeddings.isEmpty else { return [] }

        let dimension = embeddings[0].count
        var result = [Double](repeating: 0.0, count: dimension)

        for embedding in embeddings {
            for i in 0..<dimension {
                result[i] += embedding[i]
            }
        }

        let count = Double(embeddings.count)
        return result.map { $0 / count }
    }

    private func normalize(vector: [Double]) -> [Double] {
        let magnitude = sqrt(vector.reduce(0.0) { $0 + ($1 * $1) })
        guard magnitude > 0 else { return vector }
        return vector.map { $0 / magnitude }
    }
}

// MARK: - Supporting Types

/// Represents a text embedding with its vector representation
struct TextEmbedding: Identifiable, Codable {
    let id: UUID
    let text: String
    let vector: [Float]
    let createdAt: Date

    var vectorString: String {
        // For storage/debugging - convert vector to comma-separated string
        vector.map { String($0) }.joined(separator: ",")
    }
}

/// Document chunk with embedding for semantic search
struct DocumentChunk: Identifiable, Codable {
    let id: UUID
    let documentId: UUID
    let documentName: String
    let pageNumber: Int
    let text: String
    let embedding: [Float]
    let createdAt: Date

    init(documentId: UUID, documentName: String, pageNumber: Int, text: String, embedding: [Float]) {
        self.id = UUID()
        self.documentId = documentId
        self.documentName = documentName
        self.pageNumber = pageNumber
        self.text = text
        self.embedding = embedding
        self.createdAt = Date()
    }
}
