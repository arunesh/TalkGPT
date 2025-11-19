//
//  UsageStatisticsService.swift
//  TalkGPT
//
//  Created by TalkGPT on 2025-11-19.
//  Phase 3 Implementation
//

import Foundation

/// Service for tracking and managing usage statistics
class UsageStatisticsService {
    static let shared = UsageStatisticsService()

    private let defaults = UserDefaults.standard

    // Keys for UserDefaults
    private enum Keys {
        static let totalConversations = "usage_total_conversations"
        static let totalMessages = "usage_total_messages"
        static let totalDocuments = "usage_total_documents"
        static let totalExports = "usage_total_exports"
        static let totalSearches = "usage_total_searches"
        static let firstLaunchDate = "usage_first_launch_date"
        static let lastLaunchDate = "usage_last_launch_date"
        static let appLaunchCount = "usage_app_launch_count"
    }

    private init() {
        // Initialize first launch date if not set
        if defaults.object(forKey: Keys.firstLaunchDate) == nil {
            defaults.set(Date(), forKey: Keys.firstLaunchDate)
        }
    }

    // MARK: - Public Methods

    /// Records an app launch
    func recordAppLaunch() {
        defaults.set(Date(), forKey: Keys.lastLaunchDate)
        let count = defaults.integer(forKey: Keys.appLaunchCount)
        defaults.set(count + 1, forKey: Keys.appLaunchCount)
    }

    /// Records a new conversation created
    func recordConversationCreated() {
        incrementCounter(for: Keys.totalConversations)
    }

    /// Records a message sent
    func recordMessageSent() {
        incrementCounter(for: Keys.totalMessages)
    }

    /// Records a document processed
    func recordDocumentProcessed() {
        incrementCounter(for: Keys.totalDocuments)
    }

    /// Records an export
    func recordExport() {
        incrementCounter(for: Keys.totalExports)
    }

    /// Records a search performed
    func recordSearch() {
        incrementCounter(for: Keys.totalSearches)
    }

    /// Gets current usage statistics
    func getStatistics() -> UsageStatistics {
        return UsageStatistics(
            totalConversations: defaults.integer(forKey: Keys.totalConversations),
            totalMessages: defaults.integer(forKey: Keys.totalMessages),
            totalDocuments: defaults.integer(forKey: Keys.totalDocuments),
            totalExports: defaults.integer(forKey: Keys.totalExports),
            totalSearches: defaults.integer(forKey: Keys.totalSearches),
            firstLaunchDate: defaults.object(forKey: Keys.firstLaunchDate) as? Date ?? Date(),
            lastLaunchDate: defaults.object(forKey: Keys.lastLaunchDate) as? Date ?? Date(),
            appLaunchCount: defaults.integer(forKey: Keys.appLaunchCount)
        )
    }

    /// Resets all statistics (useful for testing or user request)
    func resetStatistics() {
        defaults.removeObject(forKey: Keys.totalConversations)
        defaults.removeObject(forKey: Keys.totalMessages)
        defaults.removeObject(forKey: Keys.totalDocuments)
        defaults.removeObject(forKey: Keys.totalExports)
        defaults.removeObject(forKey: Keys.totalSearches)
        defaults.removeObject(forKey: Keys.appLaunchCount)
        // Keep first/last launch dates
    }

    // MARK: - Private Helpers

    private func incrementCounter(for key: String) {
        let count = defaults.integer(forKey: key)
        defaults.set(count + 1, forKey: key)
    }
}

// MARK: - Supporting Types

struct UsageStatistics {
    let totalConversations: Int
    let totalMessages: Int
    let totalDocuments: Int
    let totalExports: Int
    let totalSearches: Int
    let firstLaunchDate: Date
    let lastLaunchDate: Date
    let appLaunchCount: Int

    var daysSinceFirstLaunch: Int {
        Calendar.current.dateComponents([.day], from: firstLaunchDate, to: Date()).day ?? 0
    }

    var averageMessagesPerDay: Double {
        let days = max(daysSinceFirstLaunch, 1)
        return Double(totalMessages) / Double(days)
    }

    var averageConversationsPerDay: Double {
        let days = max(daysSinceFirstLaunch, 1)
        return Double(totalConversations) / Double(days)
    }
}
