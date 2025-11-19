//
//  DocumentSynthesisService.swift
//  TalkGPT
//
//  Created by TalkGPT on 2025-11-19.
//  Phase 4 Implementation - Multi-Document Synthesis
//

import Foundation

/// Service for synthesizing information across multiple documents
class DocumentSynthesisService {
    static let shared = DocumentSynthesisService()

    private let llmService: LLMServiceProtocol
    private let semanticSearch = SemanticSearchService.shared

    init(llmService: LLMServiceProtocol = LLMService()) {
        self.llmService = llmService
    }

    // MARK: - Multi-Document Synthesis

    /// Synthesizes information from multiple documents to answer a query
    /// - Parameters:
    ///   - query: The user's question or topic
    ///   - documents: Documents to synthesize from
    ///   - parameters: LLM parameters
    /// - Returns: Streaming response with synthesized information
    func synthesizeFromDocuments(
        query: String,
        documents: [Document],
        parameters: ModelParameters
    ) -> AsyncThrowingStream<String, Error> {
        return llmService.generateResponse(
            query: query,
            context: documents,
            conversationHistory: [],
            parameters: parameters
        )
    }

    /// Generates a synthesis of multiple documents with citations
    /// - Parameters:
    ///   - documents: Documents to synthesize
    ///   - focusArea: Optional focus area for synthesis
    ///   - parameters: LLM parameters
    /// - Returns: Synthesis result with text and sources
    func generateSynthesis(
        documents: [Document],
        focusArea: String?,
        parameters: ModelParameters
    ) async throws -> SynthesisResult {
        guard !documents.isEmpty else {
            throw SynthesisError.noDocumentsProvided
        }

        // Build synthesis prompt
        let prompt = buildSynthesisPrompt(documents: documents, focusArea: focusArea)

        // Generate synthesis
        var synthesizedText = ""
        let stream = llmService.generateResponse(
            query: prompt,
            context: documents,
            conversationHistory: [],
            parameters: parameters
        )

        for try await token in stream {
            synthesizedText += token
        }

        // Extract key points
        let keyPoints = extractKeyPoints(from: synthesizedText)

        return SynthesisResult(
            text: synthesizedText,
            keyPoints: keyPoints,
            sourceDocuments: documents.map { ($0.id, $0.name) },
            focusArea: focusArea
        )
    }

    // MARK: - Document Summarization

    /// Summarizes a single document
    /// - Parameters:
    ///   - document: The document to summarize
    ///   - pages: The pages of the document
    ///   - summaryLength: Desired summary length
    ///   - parameters: LLM parameters
    /// - Returns: Document summary
    func summarizeDocument(
        _ document: Document,
        pages: [Page],
        summaryLength: SummaryLength = .medium,
        parameters: ModelParameters
    ) async throws -> DocumentSummary {
        let fullText = pages.map { $0.text }.joined(separator: "\n\n")

        let prompt = buildSummaryPrompt(
            documentName: document.name,
            text: fullText,
            length: summaryLength
        )

        var summaryText = ""
        let stream = llmService.generateResponse(
            query: prompt,
            context: [document],
            conversationHistory: [],
            parameters: parameters
        )

        for try await token in stream {
            summaryText += token
        }

        // Extract key topics
        let topics = extractTopics(from: fullText)

        return DocumentSummary(
            documentId: document.id,
            documentName: document.name,
            summary: summaryText,
            keyTopics: topics,
            length: summaryLength,
            pageCount: pages.count,
            generatedAt: Date()
        )
    }

    /// Generates summaries for multiple documents in batch
    /// - Parameters:
    ///   - documentsWithPages: Array of document-pages tuples
    ///   - summaryLength: Desired summary length
    ///   - parameters: LLM parameters
    /// - Returns: Array of document summaries
    func summarizeDocumentsBatch(
        _ documentsWithPages: [(Document, [Page])],
        summaryLength: SummaryLength = .short,
        parameters: ModelParameters
    ) async throws -> [DocumentSummary] {
        var summaries: [DocumentSummary] = []

        for (document, pages) in documentsWithPages {
            do {
                let summary = try await summarizeDocument(
                    document,
                    pages: pages,
                    summaryLength: summaryLength,
                    parameters: parameters
                )
                summaries.append(summary)
            } catch {
                print("Error summarizing document \(document.name): \(error)")
            }
        }

        return summaries
    }

    // MARK: - Comparative Analysis

    /// Compares and contrasts multiple documents
    /// - Parameters:
    ///   - documents: Documents to compare
    ///   - comparisonAspect: Optional specific aspect to compare
    ///   - parameters: LLM parameters
    /// - Returns: Comparison result
    func compareDocuments(
        _ documents: [Document],
        comparisonAspect: String?,
        parameters: ModelParameters
    ) async throws -> ComparisonResult {
        guard documents.count >= 2 else {
            throw SynthesisError.insufficientDocuments
        }

        let prompt = buildComparisonPrompt(
            documents: documents,
            aspect: comparisonAspect
        )

        var comparisonText = ""
        let stream = llmService.generateResponse(
            query: prompt,
            context: documents,
            conversationHistory: [],
            parameters: parameters
        )

        for try await token in stream {
            comparisonText += token
        }

        return ComparisonResult(
            text: comparisonText,
            documentsCompared: documents.map { ($0.id, $0.name) },
            aspect: comparisonAspect
        )
    }

    // MARK: - Private Helpers

    private func buildSynthesisPrompt(documents: [Document], focusArea: String?) -> String {
        var prompt = "Please synthesize the information from the provided documents"

        if let focus = focusArea {
            prompt += ", focusing on: \(focus)"
        }

        prompt += """
        .

        Create a comprehensive synthesis that:
        1. Identifies common themes and patterns across all documents
        2. Highlights unique insights from each source
        3. Presents a unified understanding of the topic
        4. Notes any contradictions or differing perspectives

        Document sources: \(documents.map { $0.name }.joined(separator: ", "))
        """

        return prompt
    }

    private func buildSummaryPrompt(documentName: String, text: String, length: SummaryLength) -> String {
        let lengthDescription = length.description

        return """
        Please provide a \(lengthDescription) summary of the following document: "\(documentName)"

        Summary requirements:
        - Capture the main ideas and key points
        - Maintain factual accuracy
        - Use clear, concise language
        - Length: \(lengthDescription)

        Document text:
        \(text.prefix(5000))
        """
    }

    private func buildComparisonPrompt(documents: [Document], aspect: String?) -> String {
        var prompt = "Please compare and contrast the following documents"

        if let aspect = aspect {
            prompt += ", specifically focusing on: \(aspect)"
        }

        prompt += """
        .

        Comparison should include:
        1. Similarities across documents
        2. Key differences and unique points
        3. Complementary information
        4. Any contradictions

        Documents to compare: \(documents.map { $0.name }.joined(separator: ", "))
        """

        return prompt
    }

    private func extractKeyPoints(from text: String) -> [String] {
        // Simple extraction of sentences with key markers
        let sentences = text.components(separatedBy: CharacterSet(charactersIn: ".!?"))

        let keyMarkers = ["important", "key", "significant", "main", "primary", "essential"]

        return sentences
            .filter { sentence in
                keyMarkers.contains { sentence.lowercased().contains($0) }
            }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .prefix(5)
            .map { $0 }
    }

    private func extractTopics(from text: String) -> [String] {
        // Simple topic extraction based on repeated key terms
        // In a production app, this would use NLP/topic modeling
        let words = text.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count > 4 } // Filter short words

        var frequency: [String: Int] = [:]
        for word in words {
            frequency[word, default: 0] += 1
        }

        return frequency
            .filter { $0.value > 2 } // Mentioned more than twice
            .sorted { $0.value > $1.value }
            .prefix(5)
            .map { $0.key.capitalized }
    }
}

// MARK: - Supporting Types

enum SummaryLength: String, CaseIterable, Identifiable {
    case brief = "Brief"
    case short = "Short"
    case medium = "Medium"
    case detailed = "Detailed"

    var id: String { rawValue }

    var description: String {
        switch self {
        case .brief:
            return "1-2 sentences"
        case .short:
            return "1 paragraph"
        case .medium:
            return "2-3 paragraphs"
        case .detailed:
            return "comprehensive overview"
        }
    }
}

struct SynthesisResult {
    let text: String
    let keyPoints: [String]
    let sourceDocuments: [(UUID, String)]
    let focusArea: String?

    var generatedAt: Date = Date()
}

struct DocumentSummary: Identifiable {
    let id = UUID()
    let documentId: UUID
    let documentName: String
    let summary: String
    let keyTopics: [String]
    let length: SummaryLength
    let pageCount: Int
    let generatedAt: Date
}

struct ComparisonResult {
    let text: String
    let documentsCompared: [(UUID, String)]
    let aspect: String?

    var generatedAt: Date = Date()
}

enum SynthesisError: LocalizedError {
    case noDocumentsProvided
    case insufficientDocuments
    case synthesisFailure

    var errorDescription: String? {
        switch self {
        case .noDocumentsProvided:
            return "No documents provided for synthesis"
        case .insufficientDocuments:
            return "At least 2 documents required for comparison"
        case .synthesisFailure:
            return "Failed to generate synthesis"
        }
    }
}
