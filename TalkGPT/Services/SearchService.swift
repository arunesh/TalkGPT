//
//  SearchService.swift
//  TalkGPT
//
//  Created by TalkGPT on 2025-11-19.
//  Phase 3 Implementation
//

import Foundation

/// Search result with context
struct SearchResult: Identifiable, Equatable {
    let id: UUID
    let documentId: UUID
    let documentName: String
    let pageId: UUID
    let pageNumber: Int
    let matchedText: String
    let context: String
    let range: Range<String.Index>
    let relevanceScore: Float

    init(
        id: UUID = UUID(),
        documentId: UUID,
        documentName: String,
        pageId: UUID,
        pageNumber: Int,
        matchedText: String,
        context: String,
        range: Range<String.Index>,
        relevanceScore: Float = 1.0
    ) {
        self.id = id
        self.documentId = documentId
        self.documentName = documentName
        self.pageId = pageId
        self.pageNumber = pageNumber
        self.matchedText = matchedText
        self.context = context
        self.range = range
        self.relevanceScore = relevanceScore
    }
}

/// Protocol for search operations
protocol SearchServiceProtocol {
    func searchInDocuments(query: String, documentIds: [UUID]?) async throws -> [SearchResult]
    func searchInDocument(query: String, documentId: UUID) async throws -> [SearchResult]
    func highlightMatches(in text: String, query: String) -> [(range: Range<String.Index>, text: String)]
}

/// Service for searching through documents
class SearchService: SearchServiceProtocol {
    private let storageService: StorageServiceProtocol

    init(storageService: StorageServiceProtocol = StorageService()) {
        self.storageService = storageService
    }

    // MARK: - Public Methods

    /// Searches for query across all or specific documents
    func searchInDocuments(query: String, documentIds: [UUID]? = nil) async throws -> [SearchResult] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }

        let documents: [Document]
        if let documentIds = documentIds {
            documents = try await fetchDocuments(by: documentIds)
        } else {
            documents = try await storageService.fetchAllDocuments()
        }

        var allResults: [SearchResult] = []

        for document in documents {
            let results = try await searchInDocument(query: query, documentId: document.id)
            allResults.append(contentsOf: results)
        }

        // Sort by relevance score
        return allResults.sorted { $0.relevanceScore > $1.relevanceScore }
    }

    /// Searches within a specific document
    func searchInDocument(query: String, documentId: UUID) async throws -> [SearchResult] {
        guard let document = try await storageService.fetchDocument(documentId) else {
            return []
        }

        let pages = try await storageService.fetchPages(for: documentId)
        var results: [SearchResult] = []

        for page in pages {
            let pageResults = searchInPage(
                query: query,
                page: page,
                documentName: document.name
            )
            results.append(contentsOf: pageResults)
        }

        return results
    }

    /// Finds all matches in text and returns ranges
    func highlightMatches(in text: String, query: String) -> [(range: Range<String.Index>, text: String)] {
        guard !query.isEmpty else { return [] }

        var matches: [(range: Range<String.Index>, text: String)] = []
        let lowercasedText = text.lowercased()
        let lowercasedQuery = query.lowercased()

        var searchRange = text.startIndex..<text.endIndex

        while let range = lowercasedText.range(of: lowercasedQuery, options: [], range: searchRange) {
            let matchedText = String(text[range])
            matches.append((range: range, text: matchedText))

            // Move search range past this match
            searchRange = range.upperBound..<text.endIndex
        }

        return matches
    }

    // MARK: - Private Methods

    /// Searches within a single page
    private func searchInPage(query: String, page: Page, documentName: String) -> [SearchResult] {
        let matches = findMatches(query: query, in: page.text)
        var results: [SearchResult] = []

        for match in matches {
            let context = extractContext(from: page.text, around: match.range, contextLength: 100)
            let relevance = calculateRelevance(query: query, match: match, pageText: page.text)

            let result = SearchResult(
                documentId: page.documentId,
                documentName: documentName,
                pageId: page.id,
                pageNumber: page.pageNumber,
                matchedText: match.text,
                context: context,
                range: match.range,
                relevanceScore: relevance
            )

            results.append(result)
        }

        return results
    }

    /// Finds all matches of query in text
    private func findMatches(query: String, in text: String) -> [(range: Range<String.Index>, text: String)] {
        return highlightMatches(in: text, query: query)
    }

    /// Extracts context around a match
    private func extractContext(from text: String, around range: Range<String.Index>, contextLength: Int) -> String {
        let startIndex = text.index(range.lowerBound, offsetBy: -contextLength, limitedBy: text.startIndex) ?? text.startIndex
        let endIndex = text.index(range.upperBound, offsetBy: contextLength, limitedBy: text.endIndex) ?? text.endIndex

        let contextRange = startIndex..<endIndex
        var context = String(text[contextRange])

        // Add ellipsis if truncated
        if startIndex != text.startIndex {
            context = "..." + context
        }
        if endIndex != text.endIndex {
            context = context + "..."
        }

        return context
    }

    /// Calculates relevance score for a match
    private func calculateRelevance(query: String, match: (range: Range<String.Index>, text: String), pageText: String) -> Float {
        var score: Float = 1.0

        // Exact case match gets higher score
        if match.text == query {
            score += 0.5
        }

        // Earlier in document gets slightly higher score
        let position = Float(pageText.distance(from: pageText.startIndex, to: match.range.lowerBound))
        let length = Float(pageText.count)
        let positionScore = 1.0 - (position / length) * 0.2

        score *= positionScore

        return score
    }

    /// Fetches multiple documents by IDs
    private func fetchDocuments(by ids: [UUID]) async throws -> [Document] {
        var documents: [Document] = []

        for id in ids {
            if let document = try await storageService.fetchDocument(id) {
                documents.append(document)
            }
        }

        return documents
    }
}

// MARK: - Advanced Search (Future Enhancement)

extension SearchService {
    /// Search with filters and options
    struct SearchOptions {
        var caseSensitive: Bool = false
        var wholeWord: Bool = false
        var regex: Bool = false
        var maxResults: Int = 100

        static let `default` = SearchOptions()
    }

    /// Advanced search with options
    func advancedSearch(query: String, options: SearchOptions = .default) async throws -> [SearchResult] {
        // TODO: Implement advanced search with regex, filters, etc.
        return try await searchInDocuments(query: query, documentIds: nil)
    }
}
