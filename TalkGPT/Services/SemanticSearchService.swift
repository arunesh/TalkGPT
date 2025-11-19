//
//  SemanticSearchService.swift
//  TalkGPT
//
//  Created by TalkGPT on 2025-11-19.
//  Phase 4 Implementation - Semantic Search
//

import Foundation

/// Service for semantic search combining vector embeddings and keyword search
class SemanticSearchService {
    static let shared = SemanticSearchService()

    private let vectorStore = VectorStore.shared
    private let keywordSearch = SearchService()

    private init() {}

    // MARK: - Public Methods

    /// Performs hybrid search combining semantic and keyword approaches
    /// - Parameters:
    ///   - query: The search query
    ///   - documentIds: Optional filter by document IDs
    ///   - searchMode: The search mode to use
    /// - Returns: Combined search results
    func search(
        query: String,
        documentIds: [UUID]? = nil,
        searchMode: SearchMode = .hybrid
    ) async throws -> [HybridSearchResult] {
        switch searchMode {
        case .keyword:
            return try await performKeywordSearch(query: query, documentIds: documentIds)

        case .semantic:
            return performSemanticSearch(query: query, documentIds: documentIds)

        case .hybrid:
            return try await performHybridSearch(query: query, documentIds: documentIds)
        }
    }

    /// Indexes a document for semantic search
    /// - Parameters:
    ///   - document: The document to index
    ///   - pages: The pages of the document
    func indexDocument(_ document: Document, pages: [Page]) async throws {
        try await vectorStore.indexDocument(document, pages: pages)
    }

    /// Removes a document from the semantic index
    /// - Parameter documentId: The document ID
    func removeDocument(_ documentId: UUID) {
        vectorStore.removeDocument(documentId)
    }

    /// Gets search statistics
    func getStats() -> SearchStats {
        let vectorStats = vectorStore.getStats()

        return SearchStats(
            indexedDocuments: vectorStats.uniqueDocuments,
            totalChunks: vectorStats.totalChunks,
            indexSize: vectorStats.formattedSize
        )
    }

    // MARK: - Private Methods

    private func performKeywordSearch(
        query: String,
        documentIds: [UUID]?
    ) async throws -> [HybridSearchResult] {
        let results = try await keywordSearch.searchInDocuments(
            query: query,
            documentIds: documentIds
        )

        return results.map { result in
            HybridSearchResult(
                documentId: result.documentId,
                documentName: result.documentName,
                pageNumber: result.pageNumber,
                text: result.context,
                relevanceScore: result.relevanceScore,
                searchMode: .keyword,
                query: query
            )
        }
    }

    private func performSemanticSearch(
        query: String,
        documentIds: [UUID]?
    ) -> [HybridSearchResult] {
        let results = vectorStore.search(
            query: query,
            limit: 20,
            documentIds: documentIds
        )

        return results.map { result in
            HybridSearchResult(
                documentId: result.documentId,
                documentName: result.documentName,
                pageNumber: result.pageNumber,
                text: result.text,
                relevanceScore: result.relevancePercentage,
                searchMode: .semantic,
                query: query
            )
        }
    }

    private func performHybridSearch(
        query: String,
        documentIds: [UUID]?
    ) async throws -> [HybridSearchResult] {
        // Perform both searches in parallel
        async let keywordResults = performKeywordSearch(query: query, documentIds: documentIds)
        let semanticResults = performSemanticSearch(query: query, documentIds: documentIds)

        let kw = try await keywordResults

        // Combine and deduplicate results
        var combinedResults: [String: HybridSearchResult] = [:]

        // Add keyword results
        for result in kw {
            let key = "\(result.documentId)_\(result.pageNumber)_\(result.text.prefix(50))"
            combinedResults[key] = result
        }

        // Add or boost semantic results
        for result in semanticResults {
            let key = "\(result.documentId)_\(result.pageNumber)_\(result.text.prefix(50))"

            if let existing = combinedResults[key] {
                // Boost score if found in both searches
                var boosted = existing
                boosted.relevanceScore = min(100, existing.relevanceScore + result.relevanceScore / 2)
                boosted.searchMode = .hybrid
                combinedResults[key] = boosted
            } else {
                combinedResults[key] = result
            }
        }

        // Sort by relevance and return
        return combinedResults.values
            .sorted { $0.relevanceScore > $1.relevanceScore }
            .prefix(20)
            .map { $0 }
    }
}

// MARK: - Supporting Types

enum SearchMode: String, CaseIterable, Identifiable {
    case keyword = "Keyword"
    case semantic = "Semantic"
    case hybrid = "Hybrid"

    var id: String { rawValue }

    var description: String {
        switch self {
        case .keyword:
            return "Fast exact matching"
        case .semantic:
            return "AI-powered meaning search"
        case .hybrid:
            return "Best of both methods"
        }
    }

    var icon: String {
        switch self {
        case .keyword:
            return "text.magnifyingglass"
        case .semantic:
            return "brain.head.profile"
        case .hybrid:
            return "sparkles.rectangle.stack"
        }
    }
}

struct HybridSearchResult: Identifiable {
    let id = UUID()
    let documentId: UUID
    let documentName: String
    let pageNumber: Int
    let text: String
    var relevanceScore: Int
    var searchMode: SearchMode
    let query: String

    var relevanceLabel: String {
        switch relevanceScore {
        case 90...100:
            return "Excellent match"
        case 70..<90:
            return "Good match"
        case 50..<70:
            return "Fair match"
        default:
            return "Weak match"
        }
    }

    var relevanceColor: String {
        switch relevanceScore {
        case 90...100:
            return "green"
        case 70..<90:
            return "blue"
        case 50..<70:
            return "orange"
        default:
            return "gray"
        }
    }
}

struct SearchStats {
    let indexedDocuments: Int
    let totalChunks: Int
    let indexSize: String
}
