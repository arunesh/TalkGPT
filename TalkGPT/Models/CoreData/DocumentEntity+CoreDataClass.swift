//
//  DocumentEntity+CoreDataClass.swift
//  TalkGPT
//
//  Created by TalkGPT on 2025-11-19.
//

import Foundation
import CoreData

@objc(DocumentEntity)
public class DocumentEntity: NSManagedObject {
    /// Converts this entity to a domain model
    func toDomain() -> Document {
        Document(
            id: id ?? UUID(),
            name: name ?? "Untitled",
            createdDate: createdDate ?? Date(),
            fileURL: URL(string: fileURL ?? "") ?? URL(fileURLWithPath: ""),
            pageCount: Int(pageCount),
            totalCharacters: Int(totalCharacters),
            thumbnailURL: thumbnailURL.flatMap { URL(string: $0) }
        )
    }

    /// Updates this entity from a domain model
    func update(from document: Document) {
        self.id = document.id
        self.name = document.name
        self.createdDate = document.createdDate
        self.fileURL = document.fileURL.absoluteString
        self.pageCount = Int32(document.pageCount)
        self.totalCharacters = Int32(document.totalCharacters)
        self.thumbnailURL = document.thumbnailURL?.absoluteString
    }
}
