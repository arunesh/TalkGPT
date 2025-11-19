//
//  Constants.swift
//  TalkGPT
//
//  Created by TalkGPT on 2025-11-19.
//

import Foundation

enum Constants {
    // MARK: - App Info

    static let appName = "TalkGPT"
    static let appVersion = "1.0.0"
    static let buildNumber = "001"

    // MARK: - Storage

    static let documentsDirectoryName = "Documents"
    static let imagesDirectoryName = "Images"
    static let thumbnailsDirectoryName = "Thumbnails"

    // MARK: - OCR

    static let defaultOCRLanguage = "en-US"
    static let minOCRConfidence: Float = 0.5

    // MARK: - UI

    static let thumbnailSize: CGFloat = 200
    static let defaultCornerRadius: CGFloat = 12
    static let cardShadowRadius: CGFloat = 5

    // MARK: - File Types

    static let supportedImageTypes = ["jpg", "jpeg", "png", "heic"]
    static let supportedDocumentTypes = ["pdf"]
    static let allSupportedTypes = supportedImageTypes + supportedDocumentTypes

    // MARK: - Limits

    static let maxDocumentNameLength = 100
    static let maxPagesPerDocument = 100
}
