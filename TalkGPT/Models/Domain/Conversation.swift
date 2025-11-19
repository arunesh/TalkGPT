//
//  Conversation.swift
//  TalkGPT
//
//  Created by TalkGPT on 2025-11-19.
//

import Foundation

/// Represents a conversation thread
struct Conversation: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var createdDate: Date
    var lastModified: Date
    var messageIds: [UUID]

    init(
        id: UUID = UUID(),
        title: String = "New Conversation",
        createdDate: Date = Date(),
        lastModified: Date = Date(),
        messageIds: [UUID] = []
    ) {
        self.id = id
        self.title = title
        self.createdDate = createdDate
        self.lastModified = lastModified
        self.messageIds = messageIds
    }
}
