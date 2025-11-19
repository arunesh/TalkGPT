//
//  OCRManager.swift
//  TalkGPT
//
//  Created by TalkGPT on 2025-11-19.
//

import Foundation
import Vision
import UIKit
import PDFKit

/// Manages OCR operations using Apple Vision framework
class OCRManager {
    static let shared = OCRManager()

    private init() {}

    // MARK: - Public Methods

    /// Extracts text from an array of images
    func extractText(from images: [UIImage]) async throws -> [PageText] {
        var results: [PageText] = []

        for (index, image) in images.enumerated() {
            let pageText = try await extractText(from: image, pageNumber: index + 1)
            results.append(pageText)
        }

        return results
    }

    /// Extracts text from a PDF file
    func extractText(from pdfURL: URL) async throws -> [PageText] {
        guard let pdfDocument = PDFDocument(url: pdfURL) else {
            throw OCRError.pdfLoadFailed
        }

        let pageCount = pdfDocument.pageCount
        var results: [PageText] = []

        for pageIndex in 0..<pageCount {
            guard let page = pdfDocument.page(at: pageIndex) else {
                continue
            }

            // Try to extract text directly from PDF first (for digital PDFs)
            let pdfText = page.string ?? ""

            if !pdfText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                // Digital PDF with extractable text
                let pageText = PageText(
                    pageNumber: pageIndex + 1,
                    text: pdfText,
                    confidence: 1.0,
                    boundingBoxes: nil
                )
                results.append(pageText)
            } else {
                // Scanned PDF, need to perform OCR
                guard let pageImage = renderPDFPageToImage(page) else {
                    continue
                }

                let pageText = try await extractText(from: pageImage, pageNumber: pageIndex + 1)
                results.append(pageText)
            }
        }

        return results
    }

    // MARK: - Private Methods

    /// Extracts text from a single image
    private func extractText(from image: UIImage, pageNumber: Int) async throws -> PageText {
        guard let cgImage = image.cgImage else {
            throw OCRError.imageProcessingFailed
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(throwing: OCRError.noTextFound)
                    return
                }

                var allText = ""
                var textBlocks: [TextBlock] = []
                var totalConfidence: Float = 0.0

                for observation in observations {
                    guard let topCandidate = observation.topCandidates(1).first else {
                        continue
                    }

                    allText += topCandidate.string + "\n"
                    totalConfidence += topCandidate.confidence

                    let textBlock = TextBlock(
                        text: topCandidate.string,
                        boundingBox: observation.boundingBox,
                        confidence: topCandidate.confidence
                    )
                    textBlocks.append(textBlock)
                }

                let averageConfidence = observations.isEmpty ? 0.0 : totalConfidence / Float(observations.count)

                let pageText = PageText(
                    pageNumber: pageNumber,
                    text: allText,
                    confidence: averageConfidence,
                    boundingBoxes: textBlocks
                )

                continuation.resume(returning: pageText)
            }

            // Configure the request for best accuracy
            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["en-US"]
            request.usesLanguageCorrection = true

            // Perform the request
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    /// Renders a PDF page to a UIImage for OCR
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

    // MARK: - Helper Methods

    /// Checks if Vision OCR is available on the device
    func isOCRAvailable() -> Bool {
        // Vision OCR is available on iOS 13+
        if #available(iOS 13.0, *) {
            return true
        }
        return false
    }

    /// Gets supported recognition languages
    func getSupportedLanguages() throws -> [String] {
        let request = VNRecognizeTextRequest()
        return try request.supportedRecognitionLanguages()
    }
}

// MARK: - Errors

enum OCRError: LocalizedError {
    case imageProcessingFailed
    case pdfLoadFailed
    case noTextFound
    case visionError(Error)

    var errorDescription: String? {
        switch self {
        case .imageProcessingFailed:
            return "Failed to process image for OCR"
        case .pdfLoadFailed:
            return "Failed to load PDF document"
        case .noTextFound:
            return "No text found in image"
        case .visionError(let error):
            return "Vision framework error: \(error.localizedDescription)"
        }
    }
}
