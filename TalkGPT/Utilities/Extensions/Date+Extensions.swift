//
//  Date+Extensions.swift
//  TalkGPT
//
//  Created by TalkGPT on 2025-11-19.
//

import Foundation

extension Date {
    /// Returns a relative date string (e.g., "2 hours ago", "Yesterday")
    var relativeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: Date())
    }

    /// Returns a short relative date string (e.g., "2h", "1d")
    var shortRelativeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }

    /// Returns a formatted date string (e.g., "Jan 15, 2024")
    var formattedString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }

    /// Returns a formatted date and time string (e.g., "Jan 15, 2024 at 3:30 PM")
    var formattedDateTimeString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
}
