//
//  DocumentSelectorSheet.swift
//  TalkGPT
//
//  Created by TalkGPT on 2025-11-19.
//  Phase 2 Implementation
//

import SwiftUI

struct DocumentSelectorSheet: View {
    @ObservedObject var viewModel: ChatViewModel
    @ObservedObject var documentsViewModel: DocumentsViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List {
                if documentsViewModel.documents.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)

                        Text("No Documents")
                            .font(.headline)

                        Text("Import documents from the Documents tab first")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                } else {
                    ForEach(documentsViewModel.documents) { document in
                        DocumentSelectRow(
                            document: document,
                            isSelected: viewModel.selectedDocuments.contains(where: { $0.id == document.id }),
                            onToggle: {
                                viewModel.toggleDocument(document)
                            }
                        )
                    }
                }
            }
            .navigationTitle("Select Documents")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !viewModel.selectedDocuments.isEmpty {
                        Button("Clear All") {
                            viewModel.clearSelectedDocuments()
                        }
                        .foregroundColor(.red)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct DocumentSelectRow: View {
    let document: Document
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(document.name)
                        .font(.body)
                        .foregroundColor(.primary)

                    HStack(spacing: 8) {
                        Text("\(document.pageCount) pages")
                            .font(.caption)

                        Text("•")
                            .font(.caption)

                        Text("\(document.totalCharacters) chars")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
        }
    }
}

struct DocumentSelectorSheet_Previews: PreviewProvider {
    static var previews: some View {
        DocumentSelectorSheet(
            viewModel: ChatViewModel(),
            documentsViewModel: DocumentsViewModel()
        )
    }
}
