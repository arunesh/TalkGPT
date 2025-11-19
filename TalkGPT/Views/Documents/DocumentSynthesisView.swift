//
//  DocumentSynthesisView.swift
//  TalkGPT
//
//  Created by TalkGPT on 2025-11-19.
//  Phase 4 Implementation - Document Synthesis UI
//

import SwiftUI

struct DocumentSynthesisView: View {
    @ObservedObject var documentsViewModel: DocumentsViewModel
    @StateObject private var viewModel = DocumentSynthesisViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Mode selector
                Picker("Mode", selection: $viewModel.mode) {
                    Label("Synthesize", systemImage: "doc.on.doc")
                        .tag(SynthesisMode.synthesize)
                    Label("Summarize", systemImage: "doc.text")
                        .tag(SynthesisMode.summarize)
                    Label("Compare", systemImage: "arrow.left.arrow.right")
                        .tag(SynthesisMode.compare)
                }
                .pickerStyle(.segmented)
                .padding()

                Divider()

                ScrollView {
                    VStack(spacing: 20) {
                        // Document selection
                        documentSelectionSection

                        // Options based on mode
                        if viewModel.mode == .summarize {
                            summarizationOptions
                        } else if viewModel.mode == .synthesize {
                            synthesisOptions
                        } else {
                            comparisonOptions
                        }

                        // Generate button
                        if !viewModel.selectedDocuments.isEmpty {
                            generateButton
                        }

                        // Results
                        if let result = viewModel.result {
                            resultSection(result: result)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Document Analysis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                viewModel.setAvailableDocuments(documentsViewModel.documents)
            }
        }
    }

    // MARK: - Subviews

    private var documentSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select Documents")
                .font(.headline)

            if viewModel.availableDocuments.isEmpty {
                Text("No documents available. Import documents first.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            } else {
                ForEach(viewModel.availableDocuments) { document in
                    DocumentSelectionRow(
                        document: document,
                        isSelected: viewModel.selectedDocuments.contains(where: { $0.id == document.id }),
                        onToggle: {
                            viewModel.toggleDocument(document)
                        }
                    )
                }
            }
        }
    }

    private var summarizationOptions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Summary Length")
                .font(.headline)

            Picker("Length", selection: $viewModel.summaryLength) {
                ForEach(SummaryLength.allCases) { length in
                    Text(length.rawValue).tag(length)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var synthesisOptions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Focus Area (Optional)")
                .font(.headline)

            TextField("e.g., main themes, conclusions, methodology", text: $viewModel.focusArea)
                .textFieldStyle(.roundedBorder)
                .autocapitalization(.none)
        }
    }

    private var comparisonOptions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Comparison Aspect (Optional)")
                .font(.headline)

            TextField("e.g., approach, findings, recommendations", text: $viewModel.comparisonAspect)
                .textFieldStyle(.roundedBorder)
                .autocapitalization(.none)

            Text("Note: Comparison requires at least 2 documents")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var generateButton: some View {
        Button(action: {
            Task {
                await viewModel.generate()
            }
        }) {
            if viewModel.isGenerating {
                HStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    Text("Generating...")
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else {
                Text(viewModel.mode.actionLabel)
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
        }
        .background(Color.blue)
        .foregroundColor(.white)
        .cornerRadius(10)
        .disabled(viewModel.isGenerating || !viewModel.canGenerate)
    }

    private func resultSection(result: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Result")
                    .font(.headline)

                Spacer()

                Button(action: {
                    UIPasteboard.general.string = result
                    HapticManager.shared.lightImpact()
                }) {
                    Label("Copy", systemImage: "doc.on.doc")
                        .font(.caption)
                }
            }

            Text(result)
                .font(.body)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .textSelection(.enabled)
        }
    }
}

// MARK: - Document Selection Row

struct DocumentSelectionRow: View {
    let document: Document
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .secondary)

                VStack(alignment: .leading, spacing: 4) {
                    Text(document.name)
                        .font(.body)
                        .foregroundColor(.primary)

                    Text("\(document.pageCount) pages")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding()
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - ViewModel

@MainActor
class DocumentSynthesisViewModel: ObservableObject {
    @Published var mode: SynthesisMode = .synthesize
    @Published var selectedDocuments: [Document] = []
    @Published var availableDocuments: [Document] = []
    @Published var focusArea: String = ""
    @Published var comparisonAspect: String = ""
    @Published var summaryLength: SummaryLength = .medium
    @Published var isGenerating: Bool = false
    @Published var result: String?

    private let synthesisService = DocumentSynthesisService.shared
    private let modelParameters = ModelParameters.default

    var canGenerate: Bool {
        switch mode {
        case .synthesize, .summarize:
            return !selectedDocuments.isEmpty
        case .compare:
            return selectedDocuments.count >= 2
        }
    }

    func setAvailableDocuments(_ documents: [Document]) {
        availableDocuments = documents
    }

    func toggleDocument(_ document: Document) {
        if selectedDocuments.contains(where: { $0.id == document.id }) {
            selectedDocuments.removeAll { $0.id == document.id }
        } else {
            selectedDocuments.append(document)
        }
        HapticManager.shared.selection()
    }

    func generate() async {
        guard canGenerate else { return }

        isGenerating = true
        result = nil

        do {
            switch mode {
            case .synthesize:
                result = try await generateSynthesis()
            case .summarize:
                result = try await generateSummaries()
            case .compare:
                result = try await generateComparison()
            }

            HapticManager.shared.success()
        } catch {
            result = "Error: \(error.localizedDescription)"
            HapticManager.shared.error()
        }

        isGenerating = false
    }

    private func generateSynthesis() async throws -> String {
        let synthesis = try await synthesisService.generateSynthesis(
            documents: selectedDocuments,
            focusArea: focusArea.isEmpty ? nil : focusArea,
            parameters: modelParameters
        )

        var output = synthesis.text

        if !synthesis.keyPoints.isEmpty {
            output += "\n\n**Key Points:**\n"
            for point in synthesis.keyPoints {
                output += "• \(point)\n"
            }
        }

        return output
    }

    private func generateSummaries() async throws -> String {
        // For now, we'll need to get pages - in a real implementation,
        // we'd fetch these from the storage service
        // This is a simplified version
        var output = ""

        for document in selectedDocuments {
            output += "**\(document.name)**\n\n"
            output += "[Summary would be generated here for \(document.pageCount) pages]\n\n"
            output += "---\n\n"
        }

        return output
    }

    private func generateComparison() async throws -> String {
        let comparison = try await synthesisService.compareDocuments(
            selectedDocuments,
            comparisonAspect: comparisonAspect.isEmpty ? nil : comparisonAspect,
            parameters: modelParameters
        )

        return comparison.text
    }
}

// MARK: - Supporting Types

enum SynthesisMode: Hashable {
    case synthesize
    case summarize
    case compare

    var actionLabel: String {
        switch self {
        case .synthesize:
            return "Generate Synthesis"
        case .summarize:
            return "Generate Summaries"
        case .compare:
            return "Compare Documents"
        }
    }
}
