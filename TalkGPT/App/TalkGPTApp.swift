//
//  TalkGPTApp.swift
//  TalkGPT
//
//  Created by TalkGPT on 2025-11-19.
//

import SwiftUI

@main
struct TalkGPTApp: App {
    // Initialize Core Data on app launch
    let coreDataManager = CoreDataManager.shared

    init() {
        // Record app launch for statistics
        UsageStatisticsService.shared.recordAppLaunch()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
