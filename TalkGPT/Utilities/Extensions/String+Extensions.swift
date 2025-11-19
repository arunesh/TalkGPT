//
//  String+Extensions.swift
//  TalkGPT
//
//  Created by TalkGPT on 2025-11-19.
//

import Foundation

extension String {
    /// Trims whitespace and newlines from both ends
    var trimmed: String {
        self.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Returns true if the string is empty after trimming
    var isBlank: Bool {
        self.trimmed.isEmpty
    }

    /// Truncates the string to a specified length
    func truncated(to length: Int, trailing: String = "...") -> String {
        if self.count > length {
            return String(self.prefix(length)) + trailing
        }
        return self
    }

    /// Returns the number of words in the string
    var wordCount: Int {
        let words = self.components(separatedBy: .whitespacesAndNewlines)
        return words.filter { !$0.isEmpty }.count
    }

    /// Returns the number of sentences in the string
    var sentenceCount: Int {
        let sentences = self.components(separatedBy: CharacterSet(charactersIn: ".!?"))
        return sentences.filter { !$0.trimmed.isEmpty }.count
    }

    /// Validates if the string is a valid filename
    var isValidFilename: Bool {
        let invalidCharacters = CharacterSet(charactersIn: "/<>:|?*\"\\")
        return self.rangeOfCharacter(from: invalidCharacters) == nil && !self.isEmpty
    }

    /// Sanitizes the string to be a valid filename
    var sanitizedFilename: String {
        let invalidCharacters = CharacterSet(charactersIn: "/<>:|?*\"\\")
        return self.components(separatedBy: invalidCharacters).joined(separator: "_")
    }
}
