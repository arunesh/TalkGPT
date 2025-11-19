//
//  ConversationListSheet.swift
//  TalkGPT
//
//  Created by TalkGPT on 2025-11-19.
//  Phase 2 Implementation
//

import SwiftUI

struct ConversationListSheet: View {
    @ObservedObject var viewModel: ChatViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var conversationToRename: Conversation?
    @State private var newTitle: String = ""
    @State private var showingRenameAlert = false

    var body: some View {
        NavigationView {
            List {
                if viewModel.conversations.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)

                        Text("No Conversations")
                            .font(.headline)

                        Text("Start chatting to create your first conversation")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                } else {
                    ForEach(viewModel.conversations) { conversation in
                        ConversationRow(
                            conversation: conversation,
                            isCurrent: viewModel.currentConversation?.id == conversation.id,
                            onSelect: {
                                viewModel.loadConversation(conversation)
                                dismiss()
                            },
                            onDelete: {
                                viewModel.deleteConversation(conversation)
                            },
                            onRename: {
                                conversationToRename = conversation
                                newTitle = conversation.title
                                showingRenameAlert = true
                            }
                        )
                    }
                }
            }
            .navigationTitle("Conversations")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        Task {
                            await viewModel.createNewConversation()
                        }
                        dismiss()
                    }) {
                        Label("New", systemImage: "square.and.pencil")
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Rename Conversation", isPresented: $showingRenameAlert) {
                TextField("Conversation Title", text: $newTitle)
                Button("Cancel", role: .cancel) {
                    conversationToRename = nil
                    newTitle = ""
                }
                Button("Rename") {
                    if let conversation = conversationToRename {
                        viewModel.renameConversation(conversation, newTitle: newTitle)
                    }
                    conversationToRename = nil
                    newTitle = ""
                }
                .disabled(newTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            } message: {
                Text("Enter a new title for this conversation")
            }
        }
    }
}

struct ConversationRow: View {
    let conversation: Conversation
    let isCurrent: Bool
    let onSelect: () -> Void
    let onDelete: () -> Void
    let onRename: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(conversation.title)
                        .font(.body)
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Text(conversation.lastModified.relativeString)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if isCurrent {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            Button(action: onRename) {
                Label("Rename", systemImage: "pencil")
            }
            .tint(.blue)
        }
    }
}

struct ConversationListSheet_Previews: PreviewProvider {
    static var previews: some View {
        ConversationListSheet(viewModel: ChatViewModel())
    }
}
