//
//  CoreDataManager.swift
//  TalkGPT
//
//  Created by TalkGPT on 2025-11-19.
//

import Foundation
import CoreData

/// Manages Core Data persistence
class CoreDataManager {
    static let shared = CoreDataManager()

    private init() {}

    // MARK: - Core Data Stack

    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "TalkGPT")

        // Create container programmatically if needed
        let description = NSPersistentStoreDescription()
        description.type = NSSQLiteStoreType
        description.shouldMigrateStoreAutomatically = true
        description.shouldInferMappingModelAutomatically = true

        container.persistentStoreDescriptions = [description]

        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                // In production, handle this error appropriately
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        return container
    }()

    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }

    // MARK: - Core Data Saving

    func saveContext() throws {
        let context = viewContext
        if context.hasChanges {
            try context.save()
        }
    }

    func performBackgroundTask<T>(_ block: @escaping (NSManagedObjectContext) throws -> T) async throws -> T {
        return try await withCheckedThrowingContinuation { continuation in
            persistentContainer.performBackgroundTask { context in
                do {
                    let result = try block(context)
                    if context.hasChanges {
                        try context.save()
                    }
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    // MARK: - Entity Creation

    func createDocumentEntity(in context: NSManagedObjectContext? = nil) -> DocumentEntity {
        let ctx = context ?? viewContext
        return DocumentEntity(context: ctx)
    }

    func createPageEntity(in context: NSManagedObjectContext? = nil) -> PageEntity {
        let ctx = context ?? viewContext
        return PageEntity(context: ctx)
    }

    // MARK: - Fetch Operations

    func fetchDocuments() throws -> [DocumentEntity] {
        let request: NSFetchRequest<DocumentEntity> = DocumentEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "createdDate", ascending: false)]
        return try viewContext.fetch(request)
    }

    func fetchDocument(by id: UUID) throws -> DocumentEntity? {
        let request: NSFetchRequest<DocumentEntity> = DocumentEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try viewContext.fetch(request).first
    }

    func fetchPages(for documentId: UUID) throws -> [PageEntity] {
        let request: NSFetchRequest<PageEntity> = PageEntity.fetchRequest()
        request.predicate = NSPredicate(format: "documentId == %@", documentId as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(key: "pageNumber", ascending: true)]
        return try viewContext.fetch(request)
    }

    // MARK: - Delete Operations

    func deleteDocument(_ entity: DocumentEntity) throws {
        viewContext.delete(entity)
        try saveContext()
    }

    func deleteAllData() throws {
        // Delete all documents
        let documentRequest: NSFetchRequest<NSFetchRequestResult> = DocumentEntity.fetchRequest()
        let documentBatchDelete = NSBatchDeleteRequest(fetchRequest: documentRequest)
        try viewContext.execute(documentBatchDelete)

        // Delete all pages
        let pageRequest: NSFetchRequest<NSFetchRequestResult> = PageEntity.fetchRequest()
        let pageBatchDelete = NSBatchDeleteRequest(fetchRequest: pageRequest)
        try viewContext.execute(pageBatchDelete)

        try saveContext()
    }
}
