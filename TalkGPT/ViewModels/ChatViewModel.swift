//
//  ChatViewModel.swift
//  TalkGPT
//
//  Created by TalkGPT on 2025-11-19.
//  Phase 2 Implementation - Complete
//

import Foundation
import Combine

/// ViewModel for managing chat interactions
@MainActor
class ChatViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var messages: [ChatMessage] = []
    @Published var selectedDocuments: [Document] = []
    @Published var currentConversation: Conversation?
    @Published var conversations: [Conversation] = []

    @Published var isGenerating: Bool = false
    @Published var currentInput: String = ""
    @Published var errorMessage: String?
    @Published var showError: Bool = false

    @Published var showDocumentSelector: Bool = false
    @Published var showConversationList: Bool = false
    @Published var showModelSettings: Bool = false

    @Published var modelParameters: ModelParameters = .default
    @Published var isModelLoaded: Bool = false
    @Published var modelInfo: ModelInfo = .none

    // Streaming response
    @Published var streamingMessage: String = ""
    @Published var isStreaming: Bool = false

    // MARK: - Private Properties

    private let llmService: LLMServiceProtocol
    private let conversationService: ConversationServiceProtocol
    private let documentService: DocumentServiceProtocol
    private let llmManager: LLMManagerProtocol

    private var cancellables = Set<AnyCancellable>()
    private var streamingTask: Task<Void, Never>?

    // MARK: - Initialization

    init(
        llmService: LLMServiceProtocol = LLMService(),
        conversationService: ConversationServiceProtocol = ConversationService(),
        documentService: DocumentServiceProtocol = DocumentService(),
        llmManager: LLMManagerProtocol = LLMManager.shared
    ) {
        self.llmService = llmService
        self.conversationService = conversationService
        self.documentService = documentService
        self.llmManager = llmManager

        // Update model status
        updateModelStatus()
    }

    // MARK: - Public Methods

    /// Initializes the chat view (called on appear)
    func initialize() {
        Task {
            await loadConversations()

            // Create a new conversation if none exists
            if currentConversation == nil {
                await createNewConversation()
            }
        }
    }

    /// Sends a message and generates a response
    func sendMessage(_ text: String? = nil) {
        let messageText = (text ?? currentInput).trimmingCharacters(in: .whitespacesAndNewlines)

        guard !messageText.isEmpty else { return }
        guard !isGenerating else { return }

        // Clear input immediately for better UX
        currentInput = ""

        Task {
            do {
                // Create conversation if needed
                if currentConversation == nil {
                    await createNewConversation()
                }

                guard let conversationId = currentConversation?.id else {
                    throw ChatError.noConversation
                }

                // Create user message
                let userMessage = ChatMessage(
                    role: .user,
                    content: messageText,
                    documentReferences: selectedDocuments.map { $0.id }
                )

                // Add to UI
                messages.append(userMessage)

                // Save user message
                try await conversationService.saveMessage(userMessage, to: conversationId)

                // Generate response
                await generateResponse(for: messageText, conversationId: conversationId)

            } catch {
                handleError(error)
            }
        }
    }

    /// Generates AI response
    private func generateResponse(for query: String, conversationId: UUID) async {
        isGenerating = true
        streamingMessage = ""
        isStreaming = true

        // Create placeholder message for streaming
        let assistantMessage = ChatMessage(
            role: .assistant,
            content: "",
            documentReferences: selectedDocuments.map { $0.id }
        )

        messages.append(assistantMessage)
        let messageIndex = messages.count - 1

        streamingTask = Task {
            do {
                // Generate response with streaming
                let stream = llmService.generateResponse(
                    query: query,
                    context: selectedDocuments,
                    conversationHistory: messages,
                    parameters: modelParameters
                )

                var fullResponse = ""

                for try await token in stream {
                    if Task.isCancelled {
                        break
                    }

                    fullResponse += token
                    streamingMessage = fullResponse

                    // Update message in real-time
                    if messageIndex < messages.count {
                        messages[messageIndex].content = fullResponse
                    }
                }

                // Save complete message
                if !fullResponse.isEmpty {
                    var finalMessage = assistantMessage
                    finalMessage.content = fullResponse
                    messages[messageIndex] = finalMessage

                    try await conversationService.saveMessage(finalMessage, to: conversationId)

                    // Update conversation title if it's the first exchange
                    await updateConversationTitle(fullResponse)
                }

            } catch {
                // Remove placeholder message on error
                if messageIndex < messages.count {
                    messages.remove(at: messageIndex)
                }
                handleError(error)
            }

            isGenerating = false
            isStreaming = false
            streamingMessage = ""
        }

        await streamingTask?.value
    }

    /// Stops the current generation
    func stopGeneration() {
        streamingTask?.cancel()
        llmService.stopGeneration()
        isGenerating = false
        isStreaming = false
    }

    /// Regenerates the last assistant message
    func regenerateLastResponse() {
        guard let lastUserMessage = messages.last(where: { $0.role == .user }) else {
            return
        }

        // Remove last assistant message if exists
        if let lastMessage = messages.last, lastMessage.role == .assistant {
            messages.removeLast()
        }

        // Regenerate
        sendMessage(lastUserMessage.content)
    }

    // MARK: - Document Management

    /// Selects a document for context
    func selectDocument(_ document: Document) {
        if !selectedDocuments.contains(where: { $0.id == document.id }) {
            selectedDocuments.append(document)
        }
    }

    /// Deselects a document
    func deselectDocument(_ document: Document) {
        selectedDocuments.removeAll { $0.id == document.id }
    }

    /// Toggles document selection
    func toggleDocument(_ document: Document) {
        if selectedDocuments.contains(where: { $0.id == document.id }) {
            deselectDocument(document)
        } else {
            selectDocument(document)
        }
    }

    /// Clears all selected documents
    func clearSelectedDocuments() {
        selectedDocuments.removeAll()
    }

    // MARK: - Conversation Management

    /// Creates a new conversation
    func createNewConversation(title: String? = nil) async {
        do {
            let conversation = try await conversationService.createConversation(title: title)
            currentConversation = conversation
            conversations.insert(conversation, at: 0)
            messages.removeAll()
            selectedDocuments.removeAll()
        } catch {
            handleError(error)
        }
    }

    /// Loads an existing conversation
    func loadConversation(_ conversation: Conversation) {
        Task {
            do {
                currentConversation = conversation

                // Load messages
                let loadedMessages = try await conversationService.fetchMessages(for: conversation.id)
                messages = loadedMessages

                // TODO: Load referenced documents from message.documentReferences

            } catch {
                handleError(error)
            }
        }
    }

    /// Loads all conversations
    func loadConversations() async {
        do {
            conversations = try await conversationService.fetchAllConversations()
        } catch {
            handleError(error)
        }
    }

    /// Deletes a conversation
    func deleteConversation(_ conversation: Conversation) {
        Task {
            do {
                try await conversationService.deleteConversation(conversation.id)
                conversations.removeAll { $0.id == conversation.id }

                // If deleted current conversation, create new one
                if currentConversation?.id == conversation.id {
                    await createNewConversation()
                }
            } catch {
                handleError(error)
            }
        }
    }

    /// Clears the current conversation
    func clearConversation() {
        messages.removeAll()
        selectedDocuments.removeAll()
        currentInput = ""
    }

    /// Updates conversation title based on first exchange
    private func updateConversationTitle(_ firstResponse: String) async {
        guard var conversation = currentConversation,
              conversation.title == "New Conversation" || conversation.title.hasPrefix("Chat") else {
            return
        }

        // Generate title from first user message
        if let firstUserMessage = messages.first(where: { $0.role == .user }) {
            let title = firstUserMessage.content.prefix(40)
            conversation.title = String(title)
            currentConversation = conversation

            do {
                try await conversationService.updateConversation(conversation)
                await loadConversations()
            } catch {
                // Ignore title update errors
            }
        }
    }

    // MARK: - Model Management

    /// Loads a model from the given path
    func loadModel(at path: URL) {
        Task {
            do {
                try await llmManager.loadModel(at: path)
                updateModelStatus()
            } catch {
                handleError(error)
            }
        }
    }

    /// Updates model parameters
    func updateParameters(_ params: ModelParameters) {
        modelParameters = params.validated()
        llmService.updateModelParameters(modelParameters)
    }

    /// Updates the model status
    private func updateModelStatus() {
        isModelLoaded = llmManager.isModelLoaded
        modelInfo = llmManager.modelInfo
    }

    // MARK: - Helper Methods

    /// Copies message content to clipboard
    func copyMessage(_ message: ChatMessage) {
        #if os(iOS)
        UIPasteboard.general.string = message.content
        #endif
    }

    /// Formats timestamp for display
    func formattedTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }

    /// Checks if message should show timestamp
    func shouldShowTimestamp(for index: Int) -> Bool {
        guard index < messages.count else { return false }

        // Show timestamp every 5 minutes
        if index == 0 { return true }

        let currentMessage = messages[index]
        let previousMessage = messages[index - 1]

        let timeDifference = currentMessage.timestamp.timeIntervalSince(previousMessage.timestamp)
        return timeDifference > 300 // 5 minutes
    }

    // MARK: - Error Handling

    private func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
        showError = true
    }

    func clearError() {
        errorMessage = nil
        showError = false
    }
}

// MARK: - Errors

enum ChatError: LocalizedError {
    case noConversation
    case sendFailed
    case loadFailed

    var errorDescription: String? {
        switch self {
        case .noConversation:
            return "No active conversation"
        case .sendFailed:
            return "Failed to send message"
        case .loadFailed:
            return "Failed to load conversation"
        }
    }
}
