//
//  ChatMessage.swift
//  TalkGPT
//
//  Created by TalkGPT on 2025-11-19.
//

import Foundation

/// Represents a message in a conversation
struct ChatMessage: Identifiable, Codable, Equatable {
    let id: UUID
    var role: MessageRole
    var content: String
    var timestamp: Date
    var documentReferences: [UUID]

    init(
        id: UUID = UUID(),
        role: MessageRole,
        content: String,
        timestamp: Date = Date(),
        documentReferences: [UUID] = []
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
        self.documentReferences = documentReferences
    }
}

/// Role of the message sender
enum MessageRole: String, Codable {
    case user
    case assistant
    case system
}
