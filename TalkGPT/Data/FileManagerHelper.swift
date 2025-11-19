//
//  FileManagerHelper.swift
//  TalkGPT
//
//  Created by TalkGPT on 2025-11-19.
//

import Foundation
import UIKit

/// Manages file storage operations for documents and images
class FileManagerHelper {
    static let shared = FileManagerHelper()

    private let fileManager = FileManager.default

    // MARK: - Directory URLs

    private lazy var documentsDirectory: URL = {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }()

    private lazy var documentsStorageDirectory: URL = {
        let url = documentsDirectory.appendingPathComponent("Documents", isDirectory: true)
        try? fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }()

    private lazy var imagesStorageDirectory: URL = {
        let url = documentsDirectory.appendingPathComponent("Images", isDirectory: true)
        try? fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }()

    private lazy var thumbnailsStorageDirectory: URL = {
        let url = documentsDirectory.appendingPathComponent("Thumbnails", isDirectory: true)
        try? fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }()

    private init() {
        setupDirectories()
    }

    // MARK: - Setup

    private func setupDirectories() {
        let directories = [documentsStorageDirectory, imagesStorageDirectory, thumbnailsStorageDirectory]
        for directory in directories {
            if !fileManager.fileExists(atPath: directory.path) {
                try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
            }
        }
    }

    // MARK: - Document Storage

    /// Saves a document file and returns its URL
    func saveDocument(data: Data, filename: String) throws -> URL {
        let fileURL = documentsStorageDirectory.appendingPathComponent(filename)
        try data.write(to: fileURL)
        return fileURL
    }

    /// Copies a file to document storage
    func copyDocument(from sourceURL: URL, filename: String) throws -> URL {
        let destinationURL = documentsStorageDirectory.appendingPathComponent(filename)

        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }

        try fileManager.copyItem(at: sourceURL, to: destinationURL)
        return destinationURL
    }

    /// Deletes a document file
    func deleteDocument(at url: URL) throws {
        if fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
        }
    }

    // MARK: - Image Storage

    /// Saves an image and returns its URL
    func saveImage(_ image: UIImage, documentId: UUID, pageNumber: Int) throws -> URL {
        let filename = "\(documentId.uuidString)_page\(pageNumber).jpg"
        let fileURL = imagesStorageDirectory.appendingPathComponent(filename)

        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw FileManagerError.imageConversionFailed
        }

        try imageData.write(to: fileURL)
        return fileURL
    }

    /// Saves multiple images and returns their URLs
    func saveImages(_ images: [UIImage], documentId: UUID) throws -> [URL] {
        var urls: [URL] = []
        for (index, image) in images.enumerated() {
            let url = try saveImage(image, documentId: documentId, pageNumber: index + 1)
            urls.append(url)
        }
        return urls
    }

    /// Deletes an image file
    func deleteImage(at url: URL) throws {
        if fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
        }
    }

    // MARK: - Thumbnail Storage

    /// Saves a thumbnail image and returns its URL
    func saveThumbnail(_ image: UIImage, documentId: UUID) throws -> URL {
        let filename = "\(documentId.uuidString)_thumb.jpg"
        let fileURL = thumbnailsStorageDirectory.appendingPathComponent(filename)

        // Create thumbnail with max dimension of 200 points
        let thumbnailImage = image.preparingThumbnail(of: CGSize(width: 200, height: 200)) ?? image

        guard let imageData = thumbnailImage.jpegData(compressionQuality: 0.7) else {
            throw FileManagerError.imageConversionFailed
        }

        try imageData.write(to: fileURL)
        return fileURL
    }

    /// Deletes a thumbnail
    func deleteThumbnail(at url: URL) throws {
        if fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
        }
    }

    // MARK: - Storage Info

    /// Returns the total storage used by the app
    func getTotalStorageUsed() -> Int64 {
        var totalSize: Int64 = 0

        let directories = [documentsStorageDirectory, imagesStorageDirectory, thumbnailsStorageDirectory]

        for directory in directories {
            if let enumerator = fileManager.enumerator(at: directory, includingPropertiesForKeys: [.fileSizeKey]) {
                for case let fileURL as URL in enumerator {
                    if let fileSize = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                        totalSize += Int64(fileSize)
                    }
                }
            }
        }

        return totalSize
    }

    /// Clears all stored files
    func clearAllData() throws {
        let directories = [documentsStorageDirectory, imagesStorageDirectory, thumbnailsStorageDirectory]

        for directory in directories {
            if fileManager.fileExists(atPath: directory.path) {
                try fileManager.removeItem(at: directory)
            }
        }

        setupDirectories()
    }

    // MARK: - Helper Methods

    /// Generates a unique filename for a document
    func generateDocumentFilename(originalName: String? = nil) -> String {
        let timestamp = Date().timeIntervalSince1970
        let uuid = UUID().uuidString.prefix(8)

        if let original = originalName {
            let nameWithoutExtension = (original as NSString).deletingPathExtension
            let ext = (original as NSString).pathExtension
            return "\(nameWithoutExtension)_\(uuid)_\(Int(timestamp)).\(ext)"
        } else {
            return "document_\(uuid)_\(Int(timestamp)).pdf"
        }
    }

    /// Checks if a file exists at the given URL
    func fileExists(at url: URL) -> Bool {
        return fileManager.fileExists(atPath: url.path)
    }

    /// Gets the size of a file in bytes
    func fileSize(at url: URL) -> Int64? {
        guard let attributes = try? fileManager.attributesOfItem(atPath: url.path) else {
            return nil
        }
        return attributes[.size] as? Int64
    }
}

// MARK: - Errors

enum FileManagerError: LocalizedError {
    case imageConversionFailed
    case fileNotFound
    case saveFailed
    case deleteFailed

    var errorDescription: String? {
        switch self {
        case .imageConversionFailed:
            return "Failed to convert image to data"
        case .fileNotFound:
            return "File not found"
        case .saveFailed:
            return "Failed to save file"
        case .deleteFailed:
            return "Failed to delete file"
        }
    }
}
