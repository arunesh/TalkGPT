//
//  PageEntity+CoreDataProperties.swift
//  TalkGPT
//
//  Created by TalkGPT on 2025-11-19.
//

import Foundation
import CoreData

extension PageEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<PageEntity> {
        return NSFetchRequest<PageEntity>(entityName: "PageEntity")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var documentId: UUID?
    @NSManaged public var pageNumber: Int32
    @NSManaged public var text: String?
    @NSManaged public var imageURL: String?
    @NSManaged public var confidence: Float
    @NSManaged public var embedding: Data?
    @NSManaged public var document: DocumentEntity?
}

extension PageEntity: Identifiable {}
