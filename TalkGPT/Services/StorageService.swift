//
//  StorageService.swift
//  TalkGPT
//
//  Created by TalkGPT on 2025-11-19.
//

import Foundation
import CoreData

/// Protocol defining storage operations
protocol StorageServiceProtocol {
    func saveDocument(_ document: Document, pages: [Page]) async throws
    func fetchDocument(_ id: UUID) async throws -> Document?
    func fetchAllDocuments() async throws -> [Document]
    func fetchPages(for documentId: UUID) async throws -> [Page]
    func deleteDocument(_ id: UUID) async throws
    func deleteAllData() async throws
}

/// Concrete implementation of storage service using Core Data
class StorageService: StorageServiceProtocol {
    private let coreDataManager = CoreDataManager.shared

    // MARK: - Save Operations

    func saveDocument(_ document: Document, pages: [Page]) async throws {
        try await coreDataManager.performBackgroundTask { context in
            // Check if document already exists
            let fetchRequest: NSFetchRequest<DocumentEntity> = DocumentEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", document.id as CVarArg)
            let existingDocuments = try context.fetch(fetchRequest)

            let documentEntity: DocumentEntity
            if let existing = existingDocuments.first {
                documentEntity = existing
            } else {
                documentEntity = DocumentEntity(context: context)
            }

            // Update document entity
            documentEntity.update(from: document)

            // Save pages
            for page in pages {
                let pageEntity = PageEntity(context: context)
                pageEntity.update(from: page)
                documentEntity.addToPages(pageEntity)
            }

            try context.save()
        }
    }

    // MARK: - Fetch Operations

    func fetchDocument(_ id: UUID) async throws -> Document? {
        return try await coreDataManager.performBackgroundTask { context in
            let fetchRequest: NSFetchRequest<DocumentEntity> = DocumentEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            fetchRequest.fetchLimit = 1

            guard let entity = try context.fetch(fetchRequest).first else {
                return nil
            }

            return entity.toDomain()
        }
    }

    func fetchAllDocuments() async throws -> [Document] {
        return try await coreDataManager.performBackgroundTask { context in
            let fetchRequest: NSFetchRequest<DocumentEntity> = DocumentEntity.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createdDate", ascending: false)]

            let entities = try context.fetch(fetchRequest)
            return entities.map { $0.toDomain() }
        }
    }

    func fetchPages(for documentId: UUID) async throws -> [Page] {
        return try await coreDataManager.performBackgroundTask { context in
            let fetchRequest: NSFetchRequest<PageEntity> = PageEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "documentId == %@", documentId as CVarArg)
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "pageNumber", ascending: true)]

            let entities = try context.fetch(fetchRequest)
            return entities.map { $0.toDomain() }
        }
    }

    // MARK: - Delete Operations

    func deleteDocument(_ id: UUID) async throws {
        try await coreDataManager.performBackgroundTask { context in
            let fetchRequest: NSFetchRequest<DocumentEntity> = DocumentEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)

            let entities = try context.fetch(fetchRequest)
            for entity in entities {
                context.delete(entity)
            }

            try context.save()
        }
    }

    func deleteAllData() async throws {
        try coreDataManager.deleteAllData()
    }

    // MARK: - Search Operations (for future use)

    func searchDocuments(query: String) async throws -> [Document] {
        return try await coreDataManager.performBackgroundTask { context in
            let fetchRequest: NSFetchRequest<DocumentEntity> = DocumentEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "name CONTAINS[cd] %@", query)
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createdDate", ascending: false)]

            let entities = try context.fetch(fetchRequest)
            return entities.map { $0.toDomain() }
        }
    }

    func searchInDocumentText(query: String) async throws -> [Page] {
        return try await coreDataManager.performBackgroundTask { context in
            let fetchRequest: NSFetchRequest<PageEntity> = PageEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "text CONTAINS[cd] %@", query)
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "pageNumber", ascending: true)]

            let entities = try context.fetch(fetchRequest)
            return entities.map { $0.toDomain() }
        }
    }
}
