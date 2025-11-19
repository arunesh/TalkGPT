//
//  ExportService.swift
//  TalkGPT
//
//  Created by TalkGPT on 2025-11-19.
//  Phase 3 Implementation
//

import Foundation
import UIKit

/// Service for exporting conversations and messages
class ExportService {
    static let shared = ExportService()

    private init() {}

    // MARK: - Export Conversation

    /// Exports conversation as plain text
    func exportAsText(conversation: Conversation, messages: [ChatMessage]) -> String {
        var output = ""

        // Header
        output += "=== \(conversation.title) ===\n"
        output += "Created: \(conversation.createdDate.formatted())\n"
        output += "Last Modified: \(conversation.lastModified.formatted())\n"
        output += "Messages: \(messages.count)\n"
        output += "\n"
        output += String(repeating: "=", count: 50)
        output += "\n\n"

        // Messages
        for message in messages {
            let roleLabel = message.role == .user ? "You" : "Assistant"
            output += "[\(message.timestamp.formatted(date: .omitted, time: .shortened))] \(roleLabel):\n"
            output += message.content
            output += "\n"

            // Citations
            if !message.citations.isEmpty {
                output += "\nSources:\n"
                for citation in message.citations {
                    output += "  • \(citation.documentName) - Page \(citation.pageNumber)\n"
                }
            }

            output += "\n" + String(repeating: "-", count: 50) + "\n\n"
        }

        return output
    }

    /// Exports conversation as Markdown
    func exportAsMarkdown(conversation: Conversation, messages: [ChatMessage]) -> String {
        var output = ""

        // Header
        output += "# \(conversation.title)\n\n"
        output += "**Created:** \(conversation.createdDate.formatted())\n\n"
        output += "**Last Modified:** \(conversation.lastModified.formatted())\n\n"
        output += "**Messages:** \(messages.count)\n\n"
        output += "---\n\n"

        // Messages
        for message in messages {
            let roleLabel = message.role == .user ? "🙋 **You**" : "🤖 **Assistant**"
            output += "### \(roleLabel)\n"
            output += "*\(message.timestamp.formatted(date: .omitted, time: .shortened))*\n\n"
            output += message.content
            output += "\n\n"

            // Citations
            if !message.citations.isEmpty {
                output += "**Sources:**\n"
                for citation in message.citations {
                    output += "- \(citation.documentName) - Page \(citation.pageNumber)\n"
                }
                output += "\n"
            }

            output += "---\n\n"
        }

        return output
    }

    /// Exports conversation as JSON
    func exportAsJSON(conversation: Conversation, messages: [ChatMessage]) throws -> String {
        let exportData = ConversationExport(
            conversation: conversation,
            messages: messages,
            exportedAt: Date()
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        let data = try encoder.encode(exportData)
        return String(data: data, encoding: .utf8) ?? ""
    }

    // MARK: - Share

    /// Creates a shareable URL for the exported content
    func createShareableFile(content: String, filename: String, format: ExportFormat) -> URL? {
        let fileManager = FileManager.default
        let tempDirectory = fileManager.temporaryDirectory
        let fileURL = tempDirectory.appendingPathComponent(filename)

        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("Error creating shareable file: \(error)")
            return nil
        }
    }

    /// Gets appropriate filename for export
    func getFilename(for conversation: Conversation, format: ExportFormat) -> String {
        let sanitized = conversation.title
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "/", with: "-")

        let timestamp = Date().formatted(date: .numeric, time: .omitted).replacingOccurrences(of: "/", with: "-")

        return "\(sanitized)_\(timestamp).\(format.fileExtension)"
    }

    // MARK: - Export Single Message

    /// Exports a single message as text
    func exportMessage(_ message: ChatMessage) -> String {
        var output = ""

        output += "[\(message.timestamp.formatted())]\n"
        output += message.content
        output += "\n"

        if !message.citations.isEmpty {
            output += "\nSources:\n"
            for citation in message.citations {
                output += "  • \(citation.documentName) - Page \(citation.pageNumber)\n"
            }
        }

        return output
    }
}

// MARK: - Supporting Types

enum ExportFormat: String, CaseIterable {
    case text = "Text"
    case markdown = "Markdown"
    case json = "JSON"

    var fileExtension: String {
        switch self {
        case .text: return "txt"
        case .markdown: return "md"
        case .json: return "json"
        }
    }

    var mimeType: String {
        switch self {
        case .text: return "text/plain"
        case .markdown: return "text/markdown"
        case .json: return "application/json"
        }
    }
}

struct ConversationExport: Codable {
    let conversation: Conversation
    let messages: [ChatMessage]
    let exportedAt: Date
    let appVersion: String = "1.0.0"

    enum CodingKeys: String, CodingKey {
        case conversation, messages
        case exportedAt = "exported_at"
        case appVersion = "app_version"
    }
}
