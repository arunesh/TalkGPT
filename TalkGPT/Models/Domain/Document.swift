//
//  Document.swift
//  TalkGPT
//
//  Created by TalkGPT on 2025-11-19.
//

import Foundation

/// Represents a document in the app
struct Document: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var createdDate: Date
    var fileURL: URL
    var pageCount: Int
    var totalCharacters: Int
    var thumbnailURL: URL?

    init(
        id: UUID = UUID(),
        name: String,
        createdDate: Date = Date(),
        fileURL: URL,
        pageCount: Int = 0,
        totalCharacters: Int = 0,
        thumbnailURL: URL? = nil
    ) {
        self.id = id
        self.name = name
        self.createdDate = createdDate
        self.fileURL = fileURL
        self.pageCount = pageCount
        self.totalCharacters = totalCharacters
        self.thumbnailURL = thumbnailURL
    }
}
