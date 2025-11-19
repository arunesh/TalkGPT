//
//  ChatView.swift
//  TalkGPT
//
//  Created by TalkGPT on 2025-11-19.
//  Phase 2 Implementation - Complete
//

import SwiftUI

struct ChatView: View {
    @StateObject private var viewModel = ChatViewModel()
    @StateObject private var documentsViewModel = DocumentsViewModel()

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Document selector bar
                if !viewModel.selectedDocuments.isEmpty {
                    documentSelectorBar
                }

                // Messages list
                if viewModel.messages.isEmpty {
                    emptyStateView
                } else {
                    messagesList
                }

                // Input bar
                inputBar
            }
            .navigationTitle(viewModel.currentConversation?.title ?? "Chat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { viewModel.showConversationList = true }) {
                        Image(systemName: "list.bullet")
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { viewModel.showDocumentSelector = true }) {
                            Label("Select Documents", systemImage: "doc.text")
                        }

                        Button(action: { viewModel.showModelSettings = true }) {
                            Label("Model Settings", systemImage: "slider.horizontal.3")
                        }

                        Divider()

                        Button(action: { viewModel.showExportSheet = true }) {
                            Label("Export Conversation", systemImage: "square.and.arrow.up")
                        }
                        .disabled(viewModel.messages.isEmpty)

                        Divider()

                        Button(role: .destructive, action: {
                            viewModel.clearConversation()
                        }) {
                            Label("Clear Conversation", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $viewModel.showDocumentSelector) {
                DocumentSelectorSheet(
                    viewModel: viewModel,
                    documentsViewModel: documentsViewModel
                )
            }
            .sheet(isPresented: $viewModel.showConversationList) {
                ConversationListSheet(viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.showModelSettings) {
                ModelSettingsSheet(viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.showExportSheet) {
                ExportConversationSheet(viewModel: viewModel)
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") {
                    viewModel.clearError()
                }
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
            .onAppear {
                viewModel.initialize()
                documentsViewModel.loadDocuments()
            }
        }
    }

    // MARK: - Subviews

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 70))
                .foregroundColor(.blue.opacity(0.5))

            Text("Start a Conversation")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Ask questions about your documents or chat freely")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            if !viewModel.isModelLoaded {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.orange)

                    Text("No model loaded")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("In production, tap Settings to load an LLM model")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(10)
                .padding()
            }

            Button(action: { viewModel.showDocumentSelector = true }) {
                Label("Select Documents to Chat", systemImage: "doc.badge.plus")
                    .font(.headline)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var documentSelectorBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(viewModel.selectedDocuments) { document in
                    DocumentChip(
                        document: document,
                        onRemove: {
                            viewModel.deselectDocument(document)
                        }
                    )
                }

                Button(action: { viewModel.showDocumentSelector = true }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                        .padding(8)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            .padding()
        }
        .background(Color(.systemGray6))
    }

    private var messagesList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(Array(viewModel.messages.enumerated()), id: \.element.id) { index, message in
                        VStack(spacing: 4) {
                            if viewModel.shouldShowTimestamp(for: index) {
                                Text(viewModel.formattedTimestamp(message.timestamp))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .padding(.vertical, 8)
                            }

                            MessageRow(
                                message: message,
                                onCopy: { viewModel.copyMessage(message) },
                                onShare: { viewModel.shareMessage(message) },
                                onRegenerate: index == viewModel.messages.count - 1 && message.role == .assistant ? {
                                    viewModel.regenerateLastResponse()
                                } : nil
                            )
                            .id(message.id)
                            .transition(.asymmetric(
                                insertion: .move(edge: message.role == .user ? .trailing : .leading).combined(with: .opacity),
                                removal: .opacity
                            ))
                        }
                    }

                    // Streaming indicator
                    if viewModel.isStreaming {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.7)
                            Text("Generating...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                    }
                }
                .padding()
            }
            .onChange(of: viewModel.messages.count) { _ in
                if let lastMessage = viewModel.messages.last {
                    withAnimation {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
    }

    private var inputBar: some View {
        VStack(spacing: 0) {
            Divider()

            HStack(spacing: 12) {
                TextField("Ask a question...", text: $viewModel.currentInput, axis: .vertical)
                    .textFieldStyle(.plain)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(20)
                    .lineLimit(1...5)
                    .disabled(viewModel.isGenerating)

                if viewModel.isGenerating {
                    Button(action: { viewModel.stopGeneration() }) {
                        Image(systemName: "stop.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.red)
                    }
                } else {
                    Button(action: { viewModel.sendMessage() }) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(viewModel.currentInput.isEmpty ? .gray : .blue)
                    }
                    .disabled(viewModel.currentInput.isEmpty)
                }
            }
            .padding()
        }
        .background(Color(.systemBackground))
    }
}

// MARK: - Supporting Views

struct MessageRow: View {
    let message: ChatMessage
    let onCopy: () -> Void
    let onShare: () -> Void
    let onRegenerate: (() -> Void)?

    @State private var showShareSheet = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if message.role == .user {
                Spacer()
            }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 8) {
                Text(message.content)
                    .font(.body)
                    .padding(12)
                    .background(message.role == .user ? Color.blue : Color(.systemGray5))
                    .foregroundColor(message.role == .user ? .white : .primary)
                    .cornerRadius(16)
                    .textSelection(.enabled)

                // Citations (for assistant messages)
                if !message.citations.isEmpty && message.role == .assistant {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Sources:")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)

                        ForEach(message.citations) { citation in
                            CitationView(citation: citation)
                        }
                    }
                    .padding(.horizontal, 4)
                }

                HStack(spacing: 16) {
                    Button(action: onCopy) {
                        Label("Copy", systemImage: "doc.on.doc")
                            .font(.caption)
                    }

                    Button(action: onShare) {
                        Label("Share", systemImage: "square.and.arrow.up")
                            .font(.caption)
                    }

                    if let regenerate = onRegenerate {
                        Button(action: regenerate) {
                            Label("Regenerate", systemImage: "arrow.clockwise")
                                .font(.caption)
                        }
                    }
                }
                .foregroundColor(.secondary)
            }

            if message.role == .assistant {
                Spacer()
            }
        }
    }
}

struct CitationView: View {
    let citation: Citation

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "doc.text")
                .font(.caption2)
                .foregroundColor(.blue)

            Text(citation.documentName)
                .font(.caption2)
                .foregroundColor(.primary)

            Text("• Page \(citation.pageNumber)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(8)
    }
}

struct DocumentChip: View {
    let document: Document
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "doc.text.fill")
                .font(.caption)

            Text(document.name)
                .font(.caption)
                .lineLimit(1)

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.blue.opacity(0.15))
        .foregroundColor(.blue)
        .cornerRadius(16)
    }
}

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        ChatView()
    }
}
