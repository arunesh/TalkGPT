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
    var citations: [Citation]

    init(
        id: UUID = UUID(),
        role: MessageRole,
        content: String,
        timestamp: Date = Date(),
        documentReferences: [UUID] = [],
        citations: [Citation] = []
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
        self.documentReferences = documentReferences
        self.citations = citations
    }
}

/// Citation referencing source in documents
struct Citation: Identifiable, Codable, Equatable {
    let id: UUID
    let documentId: UUID
    let documentName: String
    let pageNumber: Int
    let excerpt: String

    init(
        id: UUID = UUID(),
        documentId: UUID,
        documentName: String,
        pageNumber: Int,
        excerpt: String
    ) {
        self.id = id
        self.documentId = documentId
        self.documentName = documentName
        self.pageNumber = pageNumber
        self.excerpt = excerpt
    }
}

/// Role of the message sender
enum MessageRole: String, Codable {
    case user
    case assistant
    case system
}
