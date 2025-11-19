//
//  DocumentEntity+CoreDataProperties.swift
//  TalkGPT
//
//  Created by TalkGPT on 2025-11-19.
//

import Foundation
import CoreData

extension DocumentEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<DocumentEntity> {
        return NSFetchRequest<DocumentEntity>(entityName: "DocumentEntity")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var createdDate: Date?
    @NSManaged public var fileURL: String?
    @NSManaged public var pageCount: Int32
    @NSManaged public var totalCharacters: Int32
    @NSManaged public var thumbnailURL: String?
    @NSManaged public var pages: NSSet?
}

// MARK: Generated accessors for pages
extension DocumentEntity {
    @objc(addPagesObject:)
    @NSManaged public func addToPages(_ value: PageEntity)

    @objc(removePagesObject:)
    @NSManaged public func removeFromPages(_ value: PageEntity)

    @objc(addPages:)
    @NSManaged public func addToPages(_ values: NSSet)

    @objc(removePages:)
    @NSManaged public func removeFromPages(_ values: NSSet)
}

extension DocumentEntity: Identifiable {}
