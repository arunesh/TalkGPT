//
//  SettingsView.swift
//  TalkGPT
//
//  Created by TalkGPT on 2025-11-19.
//

import SwiftUI

struct SettingsView: View {
    @State private var storageUsed: Int64 = 0
    @State private var documentCount: Int = 0
    @State private var showingClearDataAlert = false

    private let fileManager = FileManagerHelper.shared
    private let storageService = StorageService()

    var body: some View {
        NavigationView {
            Form {
                // Storage Section
                Section {
                    HStack {
                        Text("Documents")
                        Spacer()
                        Text("\(documentCount)")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Storage Used")
                        Spacer()
                        Text(formattedStorageSize)
                            .foregroundColor(.secondary)
                    }

                    Button(role: .destructive, action: {
                        showingClearDataAlert = true
                    }) {
                        Text("Clear All Data")
                    }
                } header: {
                    Text("Storage")
                }

                // Model Settings Section (Phase 2)
                Section {
                    HStack {
                        Text("LLM Model")
                        Spacer()
                        Text("Not Loaded")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Temperature")
                        Spacer()
                        Text("0.7")
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Model Settings")
                } footer: {
                    Text("Model settings will be available in Phase 2")
                }

                // About Section
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0 (Phase 1)")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Build")
                        Spacer()
                        Text("001")
                            .foregroundColor(.secondary)
                    }

                    Link("Privacy Policy", destination: URL(string: "https://example.com/privacy")!)

                    Link("Open Source Licenses", destination: URL(string: "https://example.com/licenses")!)
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
            .task {
                await loadStorageInfo()
            }
            .alert("Clear All Data", isPresented: $showingClearDataAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Clear All", role: .destructive) {
                    clearAllData()
                }
            } message: {
                Text("This will delete all documents and data. This action cannot be undone.")
            }
        }
    }

    // MARK: - Computed Properties

    private var formattedStorageSize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: storageUsed)
    }

    // MARK: - Methods

    private func loadStorageInfo() async {
        storageUsed = fileManager.getTotalStorageUsed()

        do {
            let documents = try await storageService.fetchAllDocuments()
            documentCount = documents.count
        } catch {
            print("Error loading document count: \(error)")
        }
    }

    private func clearAllData() {
        Task {
            do {
                try await storageService.deleteAllData()
                try fileManager.clearAllData()

                await loadStorageInfo()
            } catch {
                print("Error clearing data: \(error)")
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
