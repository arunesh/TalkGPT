//
//  DocumentsViewModel.swift
//  TalkGPT
//
//  Created by TalkGPT on 2025-11-19.
//

import Foundation
import Combine
import UIKit
import VisionKit

/// ViewModel for managing documents
@MainActor
class DocumentsViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var documents: [Document] = []
    @Published var isImporting: Bool = false
    @Published var isProcessing: Bool = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    @Published var importProgress: Double = 0.0
    @Published var selectedDocument: Document?
    @Published var showDocumentScanner: Bool = false
    @Published var showFilePicker: Bool = false

    // MARK: - Private Properties

    private let documentService: DocumentServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(documentService: DocumentServiceProtocol = DocumentService()) {
        self.documentService = documentService
    }

    // MARK: - Public Methods

    /// Loads all documents from storage
    func loadDocuments() {
        Task {
            do {
                documents = try await documentService.getAllDocuments()
            } catch {
                handleError(error)
            }
        }
    }

    /// Imports document from camera scan
    func importFromCamera(images: [UIImage], name: String? = nil) {
        Task {
            isImporting = true
            importProgress = 0.0

            do {
                let source = DocumentSource.camera(images)
                let document = try await documentService.importDocument(from: source, name: name)

                // Add to documents list
                documents.insert(document, at: 0)
                importProgress = 1.0

            } catch {
                handleError(error)
            }

            isImporting = false
        }
    }

    /// Imports document from file
    func importFromFile(url: URL, name: String? = nil) {
        Task {
            isImporting = true
            importProgress = 0.0

            do {
                // Get security scoped access
                let _ = url.startAccessingSecurityScopedResource()
                defer { url.stopAccessingSecurityScopedResource() }

                let source = DocumentSource.file(url)
                let document = try await documentService.importDocument(from: source, name: name)

                // Add to documents list
                documents.insert(document, at: 0)
                importProgress = 1.0

            } catch {
                handleError(error)
            }

            isImporting = false
        }
    }

    /// Imports documents from photos
    func importFromPhotos(images: [UIImage], name: String? = nil) {
        Task {
            isImporting = true
            importProgress = 0.0

            do {
                let source = DocumentSource.photos(images)
                let document = try await documentService.importDocument(from: source, name: name)

                // Add to documents list
                documents.insert(document, at: 0)
                importProgress = 1.0

            } catch {
                handleError(error)
            }

            isImporting = false
        }
    }

    /// Re-processes a document (e.g., re-run OCR)
    func reprocessDocument(_ document: Document) {
        Task {
            isProcessing = true

            do {
                try await documentService.processDocument(document)

                // Refresh documents
                loadDocuments()

            } catch {
                handleError(error)
            }

            isProcessing = false
        }
    }

    /// Deletes a document
    func deleteDocument(_ document: Document) {
        Task {
            do {
                try await documentService.deleteDocument(document.id)

                // Remove from list
                documents.removeAll { $0.id == document.id }

            } catch {
                handleError(error)
            }
        }
    }

    /// Deletes multiple documents
    func deleteDocuments(at offsets: IndexSet) {
        let documentsToDelete = offsets.map { documents[$0] }

        Task {
            do {
                for document in documentsToDelete {
                    try await documentService.deleteDocument(document.id)
                }

                // Reload documents
                loadDocuments()

            } catch {
                handleError(error)
            }
        }
    }

    /// Refreshes the documents list
    func refreshDocuments() {
        loadDocuments()
    }

    /// Shows document scanner
    func showScanner() {
        showDocumentScanner = true
    }

    /// Shows file picker
    func showFileSelector() {
        showFilePicker = true
    }

    // MARK: - Helper Methods

    /// Formats file size for display
    func formattedFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    /// Formats date for display
    func formattedDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    // MARK: - Private Methods

    private func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
        showError = true
    }

    /// Clears error state
    func clearError() {
        errorMessage = nil
        showError = false
    }

    // MARK: - Document Scanner Availability

    var isDocumentScannerAvailable: Bool {
        VNDocumentCameraViewController.isSupported
    }
}
