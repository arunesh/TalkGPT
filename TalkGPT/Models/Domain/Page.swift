//
//  Page.swift
//  TalkGPT
//
//  Created by TalkGPT on 2025-11-19.
//

import Foundation

/// Represents a single page within a document
struct Page: Identifiable, Codable, Equatable {
    let id: UUID
    var documentId: UUID
    var pageNumber: Int
    var text: String
    var imageURL: URL?
    var confidence: Float

    init(
        id: UUID = UUID(),
        documentId: UUID,
        pageNumber: Int,
        text: String,
        imageURL: URL? = nil,
        confidence: Float = 0.0
    ) {
        self.id = id
        self.documentId = documentId
        self.pageNumber = pageNumber
        self.text = text
        self.imageURL = imageURL
        self.confidence = confidence
    }
}

/// Represents extracted text from OCR with metadata
struct PageText {
    let pageNumber: Int
    let text: String
    let confidence: Float
    let boundingBoxes: [TextBlock]?
}

/// Represents a block of recognized text with its location
struct TextBlock {
    let text: String
    let boundingBox: CGRect
    let confidence: Float
}
