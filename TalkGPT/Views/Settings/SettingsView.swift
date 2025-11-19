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
    @State private var conversationCount: Int = 0
    @State private var showingClearDataAlert = false
    @State private var showingClearConversationsAlert = false

    private let fileManager = FileManagerHelper.shared
    private let storageService = StorageService()
    private let conversationService = ConversationService()
    private let llmManager = LLMManager.shared

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

                    HStack {
                        Text("Conversations")
                        Spacer()
                        Text("\(conversationCount)")
                            .foregroundColor(.secondary)
                    }

                    Button(role: .destructive, action: {
                        showingClearConversationsAlert = true
                    }) {
                        Text("Clear Conversations")
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
                        Text("Status")
                        Spacer()
                        Text(llmManager.isModelLoaded ? "Loaded" : "Not Loaded")
                            .foregroundColor(llmManager.isModelLoaded ? .green : .red)
                    }

                    if llmManager.isModelLoaded {
                        HStack {
                            Text("Model")
                            Spacer()
                            Text(llmManager.modelInfo.name)
                                .foregroundColor(.secondary)
                        }

                        HStack {
                            Text("Size")
                            Spacer()
                            Text(llmManager.modelInfo.size)
                                .foregroundColor(.secondary)
                        }

                        HStack {
                            Text("Quantization")
                            Spacer()
                            Text(llmManager.modelInfo.quantization)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("LLM Model")
                } footer: {
                    if !llmManager.isModelLoaded {
                        Text("Model is running in demonstration mode. In production, you would load a GGUF model file (Gemma 2B or Phi-3 Mini recommended).")
                    }
                }

                // About Section
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0 (Phase 2)")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Build")
                        Spacer()
                        Text("002")
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
            .alert("Clear Conversations", isPresented: $showingClearConversationsAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Clear", role: .destructive) {
                    clearConversations()
                }
            } message: {
                Text("This will delete all conversations and messages. Documents will not be affected.")
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

            let stats = try await conversationService.getConversationStats()
            conversationCount = stats.count
        } catch {
            print("Error loading storage info: \(error)")
        }
    }

    private func clearAllData() {
        Task {
            do {
                try await storageService.deleteAllData()
                try await conversationService.deleteAllConversations()
                try fileManager.clearAllData()

                await loadStorageInfo()
            } catch {
                print("Error clearing data: \(error)")
            }
        }
    }

    private func clearConversations() {
        Task {
            do {
                try await conversationService.deleteAllConversations()
                await loadStorageInfo()
            } catch {
                print("Error clearing conversations: \(error)")
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
