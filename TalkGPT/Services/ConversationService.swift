//
//  ConversationService.swift
//  TalkGPT
//
//  Created by TalkGPT on 2025-11-19.
//  Phase 2 Implementation
//

import Foundation

/// Protocol for conversation management
protocol ConversationServiceProtocol {
    func createConversation(title: String?) async throws -> Conversation
    func fetchConversation(_ id: UUID) async throws -> Conversation?
    func fetchAllConversations() async throws -> [Conversation]
    func updateConversation(_ conversation: Conversation) async throws
    func deleteConversation(_ id: UUID) async throws
    func saveMessage(_ message: ChatMessage, to conversationId: UUID) async throws
    func fetchMessages(for conversationId: UUID) async throws -> [ChatMessage]
}

/// Service for managing conversations and messages
class ConversationService: ConversationServiceProtocol {
    // Using UserDefaults for simple persistence
    // In production, this could use Core Data or a dedicated database
    private let defaults = UserDefaults.standard
    private let conversationsKey = "stored_conversations"
    private let messagesKey = "stored_messages"

    // MARK: - Conversation Management

    func createConversation(title: String? = nil) async throws -> Conversation {
        let conversation = Conversation(
            title: title ?? "New Conversation"
        )

        var conversations = try await fetchAllConversations()
        conversations.insert(conversation, at: 0)

        try saveConversations(conversations)

        return conversation
    }

    func fetchConversation(_ id: UUID) async throws -> Conversation? {
        let conversations = try await fetchAllConversations()
        return conversations.first { $0.id == id }
    }

    func fetchAllConversations() async throws -> [Conversation] {
        guard let data = defaults.data(forKey: conversationsKey) else {
            return []
        }

        let decoder = JSONDecoder()
        return try decoder.decode([Conversation].self, from: data)
    }

    func updateConversation(_ conversation: Conversation) async throws {
        var conversations = try await fetchAllConversations()

        if let index = conversations.firstIndex(where: { $0.id == conversation.id }) {
            conversations[index] = conversation
            try saveConversations(conversations)
        }
    }

    func deleteConversation(_ id: UUID) async throws {
        var conversations = try await fetchAllConversations()
        conversations.removeAll { $0.id == id }
        try saveConversations(conversations)

        // Also delete associated messages
        var allMessages = try await fetchAllMessages()
        allMessages.removeAll { message in
            if let conversationId = getConversationId(for: message.id) {
                return conversationId == id
            }
            return false
        }
        try saveAllMessages(allMessages)
    }

    // MARK: - Message Management

    func saveMessage(_ message: ChatMessage, to conversationId: UUID) async throws {
        // Fetch conversation
        guard var conversation = try await fetchConversation(conversationId) else {
            throw ConversationServiceError.conversationNotFound
        }

        // Add message ID to conversation
        conversation.messageIds.append(message.id)
        conversation.lastModified = Date()

        // Update conversation
        try await updateConversation(conversation)

        // Save message
        var allMessages = try await fetchAllMessages()
        allMessages.append(message)
        try saveAllMessages(allMessages)

        // Store message-to-conversation mapping
        saveConversationId(conversationId, for: message.id)
    }

    func fetchMessages(for conversationId: UUID) async throws -> [ChatMessage] {
        guard let conversation = try await fetchConversation(conversationId) else {
            return []
        }

        let allMessages = try await fetchAllMessages()

        // Filter messages by conversation's message IDs
        let conversationMessages = allMessages.filter { message in
            conversation.messageIds.contains(message.id)
        }

        // Sort by timestamp
        return conversationMessages.sorted { $0.timestamp < $1.timestamp }
    }

    // MARK: - Private Helpers

    private func saveConversations(_ conversations: [Conversation]) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(conversations)
        defaults.set(data, forKey: conversationsKey)
    }

    private func fetchAllMessages() async throws -> [ChatMessage] {
        guard let data = defaults.data(forKey: messagesKey) else {
            return []
        }

        let decoder = JSONDecoder()
        return try decoder.decode([ChatMessage].self, from: data)
    }

    private func saveAllMessages(_ messages: [ChatMessage]) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(messages)
        defaults.set(data, forKey: messagesKey)
    }

    private func saveConversationId(_ conversationId: UUID, for messageId: UUID) {
        let key = "message_to_conversation_\(messageId.uuidString)"
        defaults.set(conversationId.uuidString, forKey: key)
    }

    private func getConversationId(for messageId: UUID) -> UUID? {
        let key = "message_to_conversation_\(messageId.uuidString)"
        guard let uuidString = defaults.string(forKey: key) else {
            return nil
        }
        return UUID(uuidString: uuidString)
    }

    // MARK: - Utilities

    func deleteAllConversations() async throws {
        defaults.removeObject(forKey: conversationsKey)
        defaults.removeObject(forKey: messagesKey)

        // Clean up message-to-conversation mappings
        // Note: In production, this would be handled by Core Data relationships
    }

    func getConversationStats() async throws -> (count: Int, totalMessages: Int) {
        let conversations = try await fetchAllConversations()
        let messages = try await fetchAllMessages()
        return (conversations.count, messages.count)
    }
}

// MARK: - Errors

enum ConversationServiceError: LocalizedError {
    case conversationNotFound
    case messageNotFound
    case saveFailed
    case loadFailed

    var errorDescription: String? {
        switch self {
        case .conversationNotFound:
            return "Conversation not found"
        case .messageNotFound:
            return "Message not found"
        case .saveFailed:
            return "Failed to save conversation"
        case .loadFailed:
            return "Failed to load conversation"
        }
    }
}
