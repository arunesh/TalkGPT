//
//  DocumentService.swift
//  TalkGPT
//
//  Created by TalkGPT on 2025-11-19.
//

import Foundation
import UIKit
import PDFKit

/// Protocol defining document management operations
protocol DocumentServiceProtocol {
    func importDocument(from source: DocumentSource, name: String?) async throws -> Document
    func processDocument(_ document: Document) async throws
    func deleteDocument(_ documentId: UUID) async throws
    func getAllDocuments() async throws -> [Document]
    func getDocumentPages(_ documentId: UUID) async throws -> [Page]
}

/// Concrete implementation of document service
class DocumentService: DocumentServiceProtocol {
    private let ocrManager = OCRManager.shared
    private let fileManager = FileManagerHelper.shared
    private let storageService: StorageServiceProtocol

    init(storageService: StorageServiceProtocol = StorageService()) {
        self.storageService = storageService
    }

    // MARK: - Import Operations

    /// Imports a document from various sources
    func importDocument(from source: DocumentSource, name: String? = nil) async throws -> Document {
        let documentId = UUID()
        let documentName = name ?? generateDocumentName(from: source)

        switch source {
        case .camera(let images):
            return try await importFromImages(images, documentId: documentId, name: documentName)

        case .file(let url):
            return try await importFromFile(url, documentId: documentId, name: documentName)

        case .photos(let images):
            return try await importFromImages(images, documentId: documentId, name: documentName)
        }
    }

    // MARK: - Process Operations

    /// Processes an already imported document (e.g., re-run OCR)
    func processDocument(_ document: Document) async throws {
        // Fetch existing pages
        let pages = try await storageService.fetchPages(for: document.id)

        // Re-process each page's image if available
        var updatedPages: [Page] = []

        for page in pages {
            if let imageURL = page.imageURL,
               let image = UIImage(contentsOfFile: imageURL.path) {
                let pageText = try await ocrManager.extractText(from: image, pageNumber: page.pageNumber)
                let updatedPage = Page(
                    id: page.id,
                    documentId: page.documentId,
                    pageNumber: page.pageNumber,
                    text: pageText.text,
                    imageURL: page.imageURL,
                    confidence: pageText.confidence
                )
                updatedPages.append(updatedPage)
            }
        }

        // Update document with new character count
        let totalChars = updatedPages.reduce(0) { $0 + $1.text.count }
        var updatedDocument = document
        updatedDocument.totalCharacters = totalChars

        // Save updated data
        try await storageService.saveDocument(updatedDocument, pages: updatedPages)
    }

    // MARK: - Fetch Operations

    func getAllDocuments() async throws -> [Document] {
        return try await storageService.fetchAllDocuments()
    }

    func getDocumentPages(_ documentId: UUID) async throws -> [Page] {
        return try await storageService.fetchPages(for: documentId)
    }

    // MARK: - Delete Operations

    func deleteDocument(_ documentId: UUID) async throws {
        // Fetch document to get file URLs
        guard let document = try await storageService.fetchDocument(documentId) else {
            throw DocumentServiceError.documentNotFound
        }

        // Delete files
        try fileManager.deleteDocument(at: document.fileURL)

        if let thumbnailURL = document.thumbnailURL {
            try fileManager.deleteThumbnail(at: thumbnailURL)
        }

        // Delete pages' image files
        let pages = try await storageService.fetchPages(for: documentId)
        for page in pages {
            if let imageURL = page.imageURL {
                try fileManager.deleteImage(at: imageURL)
            }
        }

        // Delete from database
        try await storageService.deleteDocument(documentId)
    }

    // MARK: - Private Helper Methods

    /// Imports document from images
    private func importFromImages(_ images: [UIImage], documentId: UUID, name: String) async throws -> Document {
        // Save images to storage
        let imageURLs = try fileManager.saveImages(images, documentId: documentId)

        // Generate thumbnail from first image
        let thumbnailURL = try fileManager.saveThumbnail(images[0], documentId: documentId)

        // Perform OCR on images
        let pageTexts = try await ocrManager.extractText(from: images)

        // Create pages
        var pages: [Page] = []
        for (index, pageText) in pageTexts.enumerated() {
            let page = Page(
                documentId: documentId,
                pageNumber: pageText.pageNumber,
                text: pageText.text,
                imageURL: imageURLs[index],
                confidence: pageText.confidence
            )
            pages.append(page)
        }

        // Calculate total characters
        let totalCharacters = pages.reduce(0) { $0 + $1.text.count }

        // Create a temporary file for the images (as PDF)
        let pdfURL = try createPDFFromImages(images, documentId: documentId, name: name)

        // Create document
        let document = Document(
            id: documentId,
            name: name,
            fileURL: pdfURL,
            pageCount: images.count,
            totalCharacters: totalCharacters,
            thumbnailURL: thumbnailURL
        )

        // Save to storage
        try await storageService.saveDocument(document, pages: pages)

        // Track statistics
        UsageStatisticsService.shared.recordDocumentProcessed()

        return document
    }

    /// Imports document from file (PDF or image)
    private func importFromFile(_ sourceURL: URL, documentId: UUID, name: String) async throws -> Document {
        let fileExtension = sourceURL.pathExtension.lowercased()

        if fileExtension == "pdf" {
            return try await importPDF(from: sourceURL, documentId: documentId, name: name)
        } else if ["jpg", "jpeg", "png", "heic"].contains(fileExtension) {
            // Import as image
            guard let image = UIImage(contentsOfFile: sourceURL.path) else {
                throw DocumentServiceError.invalidFile
            }
            return try await importFromImages([image], documentId: documentId, name: name)
        } else {
            throw DocumentServiceError.unsupportedFileType
        }
    }

    /// Imports a PDF document
    private func importPDF(from sourceURL: URL, documentId: UUID, name: String) async throws -> Document {
        // Copy PDF to app storage
        let filename = fileManager.generateDocumentFilename(originalName: name)
        let destinationURL = try fileManager.copyDocument(from: sourceURL, filename: filename)

        // Load PDF for processing
        guard let pdfDocument = PDFDocument(url: destinationURL) else {
            throw DocumentServiceError.pdfLoadFailed
        }

        // Create thumbnail from first page
        var thumbnailURL: URL?
        if let firstPage = pdfDocument.page(at: 0),
           let thumbnail = renderPDFPageToImage(firstPage) {
            thumbnailURL = try fileManager.saveThumbnail(thumbnail, documentId: documentId)
        }

        // Perform OCR
        let pageTexts = try await ocrManager.extractText(from: destinationURL)

        // Create pages
        var pages: [Page] = []
        for pageText in pageTexts {
            let page = Page(
                documentId: documentId,
                pageNumber: pageText.pageNumber,
                text: pageText.text,
                confidence: pageText.confidence
            )
            pages.append(page)
        }

        // Calculate total characters
        let totalCharacters = pages.reduce(0) { $0 + $1.text.count }

        // Create document
        let document = Document(
            id: documentId,
            name: name,
            fileURL: destinationURL,
            pageCount: pdfDocument.pageCount,
            totalCharacters: totalCharacters,
            thumbnailURL: thumbnailURL
        )

        // Save to storage
        try await storageService.saveDocument(document, pages: pages)

        // Track statistics
        UsageStatisticsService.shared.recordDocumentProcessed()

        return document
    }

    /// Creates a PDF from images
    private func createPDFFromImages(_ images: [UIImage], documentId: UUID, name: String) throws -> URL {
        let filename = fileManager.generateDocumentFilename(originalName: "\(name).pdf")
        let pdfURL = try fileManager.saveDocument(data: Data(), filename: filename)

        // Create PDF context
        UIGraphicsBeginPDFContextToFile(pdfURL.path, .zero, nil)

        for image in images {
            let pageRect = CGRect(origin: .zero, size: image.size)
            UIGraphicsBeginPDFPageWithInfo(pageRect, nil)

            image.draw(in: pageRect)
        }

        UIGraphicsEndPDFContext()

        return pdfURL
    }

    /// Renders a PDF page to an image
    private func renderPDFPageToImage(_ page: PDFPage) -> UIImage? {
        let pageRect = page.bounds(for: .mediaBox)
        let renderer = UIGraphicsImageRenderer(size: pageRect.size)

        let image = renderer.image { ctx in
            UIColor.white.set()
            ctx.fill(pageRect)

            ctx.cgContext.translateBy(x: 0, y: pageRect.size.height)
            ctx.cgContext.scaleBy(x: 1.0, y: -1.0)

            page.draw(with: .mediaBox, to: ctx.cgContext)
        }

        return image
    }

    /// Generates a document name from the source
    private func generateDocumentName(from source: DocumentSource) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        let timestamp = dateFormatter.string(from: Date())

        switch source {
        case .camera:
            return "Scanned Document \(timestamp)"
        case .file(let url):
            return url.deletingPathExtension().lastPathComponent
        case .photos:
            return "Photo Document \(timestamp)"
        }
    }
}

// MARK: - Errors

enum DocumentServiceError: LocalizedError {
    case documentNotFound
    case invalidFile
    case unsupportedFileType
    case pdfLoadFailed
    case ocrFailed
    case saveFailed

    var errorDescription: String? {
        switch self {
        case .documentNotFound:
            return "Document not found"
        case .invalidFile:
            return "Invalid file"
        case .unsupportedFileType:
            return "Unsupported file type"
        case .pdfLoadFailed:
            return "Failed to load PDF"
        case .ocrFailed:
            return "OCR processing failed"
        case .saveFailed:
            return "Failed to save document"
        }
    }
}
