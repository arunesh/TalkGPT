//
//  DocumentDetailView.swift
//  TalkGPT
//
//  Created by TalkGPT on 2025-11-19.
//

import SwiftUI
import PDFKit

struct DocumentDetailView: View {
    let document: Document
    @ObservedObject var viewModel: DocumentsViewModel

    @State private var pages: [Page] = []
    @State private var isLoading = false
    @State private var selectedView: ViewMode = .preview

    enum ViewMode {
        case preview
        case text
    }

    var body: some View {
        VStack(spacing: 0) {
            // View mode picker
            Picker("View", selection: $selectedView) {
                Text("Preview").tag(ViewMode.preview)
                Text("Text").tag(ViewMode.text)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()

            // Content
            if isLoading {
                ProgressView("Loading...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                switch selectedView {
                case .preview:
                    previewView
                case .text:
                    textView
                }
            }
        }
        .navigationTitle(document.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { reprocess() }) {
                        Label("Re-process OCR", systemImage: "arrow.clockwise")
                    }

                    Button(action: { shareDocument() }) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .task {
            await loadPages()
        }
    }

    // MARK: - Subviews

    private var previewView: some View {
        PDFKitView(url: document.fileURL)
    }

    private var textView: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                ForEach(pages) { page in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Page \(page.pageNumber)")
                                .font(.headline)
                                .foregroundColor(.primary)

                            Spacer()

                            if page.confidence > 0 {
                                ConfidenceBadge(confidence: page.confidence)
                            }
                        }

                        Text(page.text)
                            .font(.body)
                            .foregroundColor(.primary)
                            .textSelection(.enabled)

                        Divider()
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }

    // MARK: - Actions

    private func loadPages() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let documentService = DocumentService()
            pages = try await documentService.getDocumentPages(document.id)
        } catch {
            print("Error loading pages: \(error)")
        }
    }

    private func reprocess() {
        viewModel.reprocessDocument(document)
    }

    private func shareDocument() {
        // TODO: Implement share functionality
        print("Share document: \(document.name)")
    }
}

// MARK: - Supporting Views

struct PDFKitView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical

        if let document = PDFDocument(url: url) {
            pdfView.document = document
        }

        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        // Update if needed
    }
}

struct ConfidenceBadge: View {
    let confidence: Float

    var body: some View {
        let percentage = Int(confidence * 100)
        let color: Color = {
            if confidence >= 0.9 { return .green }
            else if confidence >= 0.7 { return .orange }
            else { return .red }
        }()

        Text("\(percentage)%")
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color)
            .cornerRadius(8)
    }
}

// MARK: - Preview

struct DocumentDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            DocumentDetailView(
                document: Document(
                    name: "Sample Document",
                    fileURL: URL(fileURLWithPath: "/sample.pdf"),
                    pageCount: 5,
                    totalCharacters: 2500
                ),
                viewModel: DocumentsViewModel()
            )
        }
    }
}
