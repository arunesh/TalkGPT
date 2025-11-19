//
//  PageEntity+CoreDataClass.swift
//  TalkGPT
//
//  Created by TalkGPT on 2025-11-19.
//

import Foundation
import CoreData

@objc(PageEntity)
public class PageEntity: NSManagedObject {
    /// Converts this entity to a domain model
    func toDomain() -> Page {
        Page(
            id: id ?? UUID(),
            documentId: documentId ?? UUID(),
            pageNumber: Int(pageNumber),
            text: text ?? "",
            imageURL: imageURL.flatMap { URL(string: $0) },
            confidence: confidence
        )
    }

    /// Updates this entity from a domain model
    func update(from page: Page) {
        self.id = page.id
        self.documentId = page.documentId
        self.pageNumber = Int32(page.pageNumber)
        self.text = page.text
        self.imageURL = page.imageURL?.absoluteString
        self.confidence = page.confidence
    }
}
