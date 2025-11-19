//
//  ChatViewModel.swift
//  TalkGPT
//
//  Created by TalkGPT on 2025-11-19.
//  Phase 2 Implementation
//

import Foundation
import Combine

/// ViewModel for managing chat interactions (Phase 2)
@MainActor
class ChatViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var messages: [ChatMessage] = []
    @Published var selectedDocuments: [Document] = []
    @Published var isGenerating: Bool = false
    @Published var currentInput: String = ""
    @Published var errorMessage: String?
    @Published var showError: Bool = false

    // MARK: - Private Properties

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init() {
        // Phase 2: Initialize LLM service
    }

    // MARK: - Public Methods (Placeholder for Phase 2)

    func sendMessage(_ text: String) {
        // TODO: Implement in Phase 2
        print("Phase 2: Send message - \(text)")
    }

    func selectDocument(_ document: Document) {
        if !selectedDocuments.contains(where: { $0.id == document.id }) {
            selectedDocuments.append(document)
        }
    }

    func deselectDocument(_ document: Document) {
        selectedDocuments.removeAll { $0.id == document.id }
    }

    func clearConversation() {
        messages.removeAll()
        currentInput = ""
    }

    func stopGeneration() {
        isGenerating = false
        // TODO: Stop LLM generation in Phase 2
    }
}
