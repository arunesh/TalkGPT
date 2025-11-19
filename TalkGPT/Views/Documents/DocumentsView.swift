//
//  DocumentsView.swift
//  TalkGPT
//
//  Created by TalkGPT on 2025-11-19.
//

import SwiftUI
import VisionKit

struct DocumentsView: View {
    @StateObject private var viewModel = DocumentsViewModel()
    @State private var showingImportOptions = false
    @State private var showingDeleteConfirmation = false
    @State private var showingSearch = false
    @State private var showingSynthesis = false
    @State private var documentToDelete: Document?

    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.documents.isEmpty {
                    emptyStateView
                } else {
                    documentsList
                }

                if viewModel.isImporting || viewModel.isProcessing {
                    loadingOverlay
                }
            }
            .navigationTitle("My Documents")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !viewModel.documents.isEmpty {
                        HStack(spacing: 16) {
                            Button(action: { showingSearch = true }) {
                                Image(systemName: "magnifyingglass")
                            }

                            Button(action: { showingSynthesis = true }) {
                                Image(systemName: "sparkles.rectangle.stack")
                            }
                        }
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingImportOptions = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $viewModel.showDocumentScanner) {
                DocumentScannerView(viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.showFilePicker) {
                DocumentPickerView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingSearch) {
                DocumentSearchView()
            }
            .sheet(isPresented: $showingSynthesis) {
                DocumentSynthesisView(documentsViewModel: viewModel)
            }
            .confirmationDialog("Import Document", isPresented: $showingImportOptions) {
                if viewModel.isDocumentScannerAvailable {
                    Button("Scan with Camera") {
                        viewModel.showScanner()
                    }
                }

                Button("Choose from Files") {
                    viewModel.showFileSelector()
                }

                Button("Cancel", role: .cancel) {}
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
            .alert("Delete Document", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    if let document = documentToDelete {
                        viewModel.deleteDocument(document)
                    }
                }
            } message: {
                Text("Are you sure you want to delete this document? This action cannot be undone.")
            }
            .onAppear {
                viewModel.loadDocuments()
            }
        }
    }

    // MARK: - Subviews

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text")
                .font(.system(size: 70))
                .foregroundColor(.gray)

            Text("No Documents")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Tap + to add your first document")
                .font(.body)
                .foregroundColor(.secondary)

            Button(action: { showingImportOptions = true }) {
                Label("Add Document", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.top)
        }
    }

    private var documentsList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.documents) { document in
                    NavigationLink(destination: DocumentDetailView(document: document, viewModel: viewModel)) {
                        DocumentCardView(
                            document: document,
                            onDelete: {
                                documentToDelete = document
                                showingDeleteConfirmation = true
                            }
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding()
        }
        .refreshable {
            viewModel.refreshDocuments()
        }
    }

    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)

                Text(viewModel.isImporting ? "Importing Document..." : "Processing...")
                    .font(.headline)
                    .foregroundColor(.white)

                if viewModel.importProgress > 0 && viewModel.importProgress < 1 {
                    ProgressView(value: viewModel.importProgress)
                        .frame(width: 200)
                        .tint(.white)
                }
            }
            .padding(30)
            .background(Color.gray.opacity(0.9))
            .cornerRadius(15)
        }
    }
}

// MARK: - Preview

struct DocumentsView_Previews: PreviewProvider {
    static var previews: some View {
        DocumentsView()
    }
}
