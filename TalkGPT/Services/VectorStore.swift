//
//  VectorStore.swift
//  TalkGPT
//
//  Created by TalkGPT on 2025-11-19.
//  Phase 4 Implementation - Vector Search
//

import Foundation

/// In-memory vector store for document embeddings
class VectorStore {
    static let shared = VectorStore()

    private var documentChunks: [DocumentChunk] = []
    private let defaults = UserDefaults.standard
    private let storageKey = "vector_store_chunks"

    private let embeddingManager = EmbeddingManager.shared

    private init() {
        loadFromStorage()
    }

    // MARK: - Public Methods

    /// Indexes a document by creating chunks and embeddings
    /// - Parameters:
    ///   - document: The document to index
    ///   - pages: The pages of the document
    func indexDocument(_ document: Document, pages: [Page]) async throws {
        // Remove existing chunks for this document
        documentChunks.removeAll { $0.documentId == document.id }

        var newChunks: [DocumentChunk] = []

        for page in pages {
            // Split page text into chunks (paragraphs or sentences)
            let chunks = chunkText(page.text, maxLength: 500)

            for chunkText in chunks {
                if let embedding = embeddingManager.embed(text: chunkText) {
                    let chunk = DocumentChunk(
                        documentId: document.id,
                        documentName: document.name,
                        pageNumber: page.pageNumber,
                        text: chunkText,
                        embedding: embedding
                    )
                    newChunks.append(chunk)
                }
            }
        }

        documentChunks.append(contentsOf: newChunks)
        saveToStorage()
    }

    /// Searches for similar chunks using semantic similarity
    /// - Parameters:
    ///   - query: The search query
    ///   - limit: Maximum number of results
    ///   - documentIds: Optional filter by document IDs
    /// - Returns: Array of semantic search results
    func search(query: String, limit: Int = 10, documentIds: [UUID]? = nil) -> [SemanticSearchResult] {
        guard let queryEmbedding = embeddingManager.embed(text: query) else {
            return []
        }

        var results: [SemanticSearchResult] = []

        // Filter chunks by document IDs if provided
        let chunksToSearch = documentIds == nil
            ? documentChunks
            : documentChunks.filter { documentIds!.contains($0.documentId) }

        // Calculate similarity for each chunk
        for chunk in chunksToSearch {
            let similarity = embeddingManager.cosineSimilarity(
                vector1: queryEmbedding,
                vector2: chunk.embedding
            )

            results.append(SemanticSearchResult(
                chunk: chunk,
                similarity: similarity,
                query: query
            ))
        }

        // Sort by similarity and return top results
        return results
            .sorted { $0.similarity > $1.similarity }
            .prefix(limit)
            .map { $0 }
    }

    /// Removes all chunks for a specific document
    /// - Parameter documentId: The document ID
    func removeDocument(_ documentId: UUID) {
        documentChunks.removeAll { $0.documentId == documentId }
        saveToStorage()
    }

    /// Clears all stored embeddings
    func clearAll() {
        documentChunks.removeAll()
        saveToStorage()
    }

    /// Gets statistics about the vector store
    func getStats() -> VectorStoreStats {
        let uniqueDocuments = Set(documentChunks.map { $0.documentId }).count
        let totalChunks = documentChunks.count
        let avgChunksPerDoc = totalChunks > 0 && uniqueDocuments > 0
            ? Double(totalChunks) / Double(uniqueDocuments)
            : 0.0

        return VectorStoreStats(
            totalChunks: totalChunks,
            uniqueDocuments: uniqueDocuments,
            averageChunksPerDocument: avgChunksPerDoc,
            totalSize: estimateSize()
        )
    }

    // MARK: - Private Helpers

    private func chunkText(_ text: String, maxLength: Int) -> [String] {
        // Split by sentences or paragraphs
        let sentences = text.components(separatedBy: CharacterSet(charactersIn: ".!?\n"))

        var chunks: [String] = []
        var currentChunk = ""

        for sentence in sentences {
            let trimmed = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }

            if currentChunk.count + trimmed.count > maxLength {
                // Add current chunk and start new one
                if !currentChunk.isEmpty {
                    chunks.append(currentChunk)
                }
                currentChunk = trimmed
            } else {
                currentChunk += (currentChunk.isEmpty ? "" : ". ") + trimmed
            }
        }

        // Add final chunk
        if !currentChunk.isEmpty {
            chunks.append(currentChunk)
        }

        return chunks
    }

    private func saveToStorage() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(documentChunks)
            defaults.set(data, forKey: storageKey)
        } catch {
            print("Error saving vector store: \(error)")
        }
    }

    private func loadFromStorage() {
        guard let data = defaults.data(forKey: storageKey) else { return }

        do {
            let decoder = JSONDecoder()
            documentChunks = try decoder.decode([DocumentChunk].self, from: data)
        } catch {
            print("Error loading vector store: \(error)")
            documentChunks = []
        }
    }

    private func estimateSize() -> Int64 {
        // Estimate size in bytes
        // Each float is 4 bytes, plus text overhead
        var size: Int64 = 0

        for chunk in documentChunks {
            size += Int64(chunk.embedding.count * 4) // Vector size
            size += Int64(chunk.text.utf8.count) // Text size
            size += 100 // Overhead for IDs, dates, etc.
        }

        return size
    }
}

// MARK: - Supporting Types

struct SemanticSearchResult: Identifiable {
    let id = UUID()
    let chunk: DocumentChunk
    let similarity: Float
    let query: String

    var documentId: UUID { chunk.documentId }
    var documentName: String { chunk.documentName }
    var pageNumber: Int { chunk.pageNumber }
    var text: String { chunk.text }

    var relevancePercentage: Int {
        Int(similarity * 100)
    }
}

struct VectorStoreStats {
    let totalChunks: Int
    let uniqueDocuments: Int
    let averageChunksPerDocument: Double
    let totalSize: Int64

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }
}
