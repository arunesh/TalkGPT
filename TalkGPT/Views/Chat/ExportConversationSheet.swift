//
//  ExportConversationSheet.swift
//  TalkGPT
//
//  Created by TalkGPT on 2025-11-19.
//  Phase 3 Implementation
//

import SwiftUI

struct ExportConversationSheet: View {
    @ObservedObject var viewModel: ChatViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedFormat: ExportFormat = .markdown
    @State private var isExporting = false
    @State private var showShareSheet = false
    @State private var exportURL: URL?

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 50))
                        .foregroundColor(.blue)

                    Text("Export Conversation")
                        .font(.title2)
                        .fontWeight(.semibold)

                    if let conversation = viewModel.currentConversation {
                        Text(conversation.title)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top)

                // Format Selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("Select Format")
                        .font(.headline)
                        .padding(.horizontal)

                    ForEach(ExportFormat.allCases, id: \.self) { format in
                        Button(action: {
                            selectedFormat = format
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                    Text(format.rawValue)
                                        .font(.body)
                                        .foregroundColor(.primary)

                                    Text(format.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                if selectedFormat == format {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.blue)
                                } else {
                                    Image(systemName: "circle")
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(selectedFormat == format ? Color.blue.opacity(0.1) : Color(.systemGray6))
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)

                Spacer()

                // Export Button
                Button(action: exportConversation) {
                    if isExporting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(maxWidth: .infinity)
                    } else {
                        Label("Export & Share", systemImage: "square.and.arrow.up")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding()
                .disabled(isExporting || viewModel.messages.isEmpty)
            }
            .navigationTitle("Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = exportURL {
                    ShareSheet(items: [url])
                }
            }
        }
    }

    // MARK: - Methods

    private func exportConversation() {
        guard let conversation = viewModel.currentConversation else { return }

        isExporting = true

        Task {
            do {
                let content = try await viewModel.exportConversation(format: selectedFormat)
                let filename = ExportService.shared.getFilename(for: conversation, format: selectedFormat)

                if let url = ExportService.shared.createShareableFile(
                    content: content,
                    filename: filename,
                    format: selectedFormat
                ) {
                    exportURL = url
                    showShareSheet = true

                    // Track statistics
                    UsageStatisticsService.shared.recordExport()
                }

                isExporting = false
            } catch {
                isExporting = false
                // Error will be handled by viewModel
            }
        }
    }
}

// MARK: - Supporting Views

extension ExportFormat {
    var description: String {
        switch self {
        case .text:
            return "Plain text format (.txt)"
        case .markdown:
            return "Formatted markdown (.md)"
        case .json:
            return "Structured JSON data (.json)"
        }
    }
}

// Share Sheet for iOS
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct ExportConversationSheet_Previews: PreviewProvider {
    static var previews: some View {
        ExportConversationSheet(viewModel: ChatViewModel())
    }
}
