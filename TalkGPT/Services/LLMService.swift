//
//  LLMService.swift
//  TalkGPT
//
//  Created by TalkGPT on 2025-11-19.
//  Phase 2 Implementation
//

import Foundation

/// Protocol for LLM service operations
protocol LLMServiceProtocol {
    func generateResponse(
        query: String,
        context: [Document],
        conversationHistory: [ChatMessage],
        parameters: ModelParameters
    ) -> AsyncThrowingStream<String, Error>

    func stopGeneration()
    func updateModelParameters(_ params: ModelParameters)
    var currentParameters: ModelParameters { get }
}

/// Service for managing LLM-based chat functionality
class LLMService: LLMServiceProtocol {
    private let llmManager: LLMManagerProtocol
    private let storageService: StorageServiceProtocol

    private(set) var currentParameters: ModelParameters = .default

    init(
        llmManager: LLMManagerProtocol = LLMManager.shared,
        storageService: StorageServiceProtocol = StorageService()
    ) {
        self.llmManager = llmManager
        self.storageService = storageService
    }

    // MARK: - Public Methods

    /// Generates a response based on query, document context, and conversation history
    func generateResponse(
        query: String,
        context: [Document],
        conversationHistory: [ChatMessage],
        parameters: ModelParameters = .default
    ) -> AsyncThrowingStream<String, Error> {
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    // Build the prompt with context
                    let prompt = try await self.buildPrompt(
                        query: query,
                        documents: context,
                        history: conversationHistory
                    )

                    // Generate response using LLM
                    let stream = self.llmManager.generate(prompt: prompt, parameters: parameters)

                    // Forward the stream
                    for try await token in stream {
                        continuation.yield(token)
                    }

                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    /// Stops the current generation
    func stopGeneration() {
        llmManager.stopGeneration()
    }

    /// Updates the model parameters
    func updateModelParameters(_ params: ModelParameters) {
        currentParameters = params.validated()
    }

    // MARK: - Prompt Engineering

    /// Builds a complete prompt with system instructions, context, and history
    private func buildPrompt(
        query: String,
        documents: [Document],
        history: [ChatMessage]
    ) async throws -> String {
        var promptParts: [String] = []

        // 1. System instructions
        promptParts.append(systemPrompt)

        // 2. Document context (if any)
        if !documents.isEmpty {
            let contextText = try await buildDocumentContext(documents)
            promptParts.append(contextText)
        }

        // 3. Conversation history (last N messages)
        if !history.isEmpty {
            let historyText = buildConversationHistory(history)
            promptParts.append(historyText)
        }

        // 4. Current query
        promptParts.append("Human: \(query)")
        promptParts.append("Assistant:")

        return promptParts.joined(separator: "\n\n")
    }

    /// System prompt that defines the assistant's behavior
    private var systemPrompt: String {
        """
        You are a helpful AI assistant specialized in answering questions about documents. \
        You have access to text extracted from documents via OCR. Your role is to:

        1. Answer questions accurately based on the provided document context
        2. Cite specific information when possible
        3. Admit when information is not in the documents
        4. Be concise but thorough in your responses
        5. Ask clarifying questions if needed

        When documents are provided, focus your answers on their content. \
        If no documents are provided, respond helpfully to general queries.
        """
    }

    /// Builds context text from selected documents
    private func buildDocumentContext(_ documents: [Document]) async throws -> String {
        var contextParts: [String] = ["DOCUMENT_CONTEXT:"]

        for (index, document) in documents.enumerated() {
            // Fetch pages for this document
            let pages = try await storageService.fetchPages(for: document.id)

            // Create document section
            var docText = "--- Document \(index + 1): \(document.name) ---\n"

            // Add text from each page, with a character limit to fit in context
            let pageTexts = pages.prefix(20).map { page in
                "Page \(page.pageNumber):\n\(page.text.prefix(2000))"
            }

            docText += pageTexts.joined(separator: "\n\n")
            contextParts.append(docText)
        }

        // Add instruction about using context
        contextParts.append("""
        ---
        Use the above document content to answer the following question. \
        If the answer is not in the documents, say so clearly.
        """)

        return contextParts.joined(separator: "\n\n")
    }

    /// Builds conversation history text
    private func buildConversationHistory(_ history: [ChatMessage]) -> String {
        // Include last 5 messages for context
        let recentHistory = Array(history.suffix(5))

        let historyText = recentHistory.map { message in
            let role = message.role == .user ? "Human" : "Assistant"
            return "\(role): \(message.content)"
        }.joined(separator: "\n\n")

        return "CONVERSATION_HISTORY:\n\(historyText)"
    }

    // MARK: - Context Management

    /// Calculates the approximate token count for text
    /// This is a rough estimation (4 characters ≈ 1 token)
    func estimateTokenCount(_ text: String) -> Int {
        return text.count / 4
    }

    /// Truncates document context to fit within token limit
    func truncateContext(_ text: String, maxTokens: Int) -> String {
        let maxChars = maxTokens * 4
        if text.count <= maxChars {
            return text
        }

        return String(text.prefix(maxChars)) + "\n\n[Content truncated due to length...]"
    }

    /// Determines if documents should be included based on context size
    func shouldIncludeDocuments(_ documents: [Document], query: String) -> Bool {
        // Simple heuristic: if query seems document-specific, include them
        let documentKeywords = ["document", "page", "text", "what does it say", "according to"]
        let lowercaseQuery = query.lowercased()

        return documentKeywords.contains { lowercaseQuery.contains($0) } || !documents.isEmpty
    }
}

// MARK: - Prompt Templates

extension LLMService {
    /// Different prompt templates for different use cases

    enum PromptTemplate {
        case summarize
        case questionAnswer
        case compare
        case extract

        var template: String {
            switch self {
            case .summarize:
                return """
                Please provide a concise summary of the following document(s). \
                Focus on the main points and key information.
                """

            case .questionAnswer:
                return """
                Based on the provided document(s), please answer the following question accurately. \
                Cite specific sections when possible.
                """

            case .compare:
                return """
                Compare and contrast the information in the provided documents. \
                Highlight similarities and differences.
                """

            case .extract:
                return """
                Extract the following information from the document(s): {query}
                Present the findings in a clear, organized format.
                """
            }
        }
    }

    /// Applies a template to a query
    func applyTemplate(_ template: PromptTemplate, to query: String) -> String {
        switch template {
        case .extract:
            return template.template.replacingOccurrences(of: "{query}", with: query)
        default:
            return template.template + "\n\n" + query
        }
    }
}
