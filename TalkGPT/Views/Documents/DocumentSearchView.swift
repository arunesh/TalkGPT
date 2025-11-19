//
//  DocumentSearchView.swift
//  TalkGPT
//
//  Created by TalkGPT on 2025-11-19.
//  Phase 3 Implementation
//

import SwiftUI

struct DocumentSearchView: View {
    @StateObject private var viewModel = DocumentSearchViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)

                    TextField("Search in documents...", text: $viewModel.searchQuery)
                        .textFieldStyle(.plain)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)

                    if !viewModel.searchQuery.isEmpty {
                        Button(action: { viewModel.clearSearch() }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))

                // Search mode picker
                Picker("Search Mode", selection: $viewModel.searchMode) {
                    ForEach(SearchMode.allCases) { mode in
                        Label(mode.rawValue, systemImage: mode.icon)
                            .tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 8)

                Divider()

                // Results
                if viewModel.isSearching {
                    ProgressView("Searching...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.searchQuery.isEmpty {
                    emptyStateView
                } else if viewModel.searchResults.isEmpty {
                    noResultsView
                } else {
                    searchResultsList
                }
            }
            .navigationTitle("Search Documents")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Subviews

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 70))
                .foregroundColor(.gray.opacity(0.5))

            Text("Search Your Documents")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Enter keywords to search across all your documents")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var noResultsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 70))
                .foregroundColor(.orange.opacity(0.5))

            Text("No Results")
                .font(.title2)
                .fontWeight(.semibold)

            Text("No matches found for '\(viewModel.searchQuery)'")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var searchResultsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                // Results summary
                HStack {
                    Text("\(viewModel.searchResults.count) result\(viewModel.searchResults.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    if viewModel.searchMode == .hybrid || viewModel.searchMode == .semantic {
                        Text(viewModel.searchMode.rawValue)
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
                .padding(.top)

                // Results
                ForEach(viewModel.searchResults) { result in
                    HybridSearchResultRow(
                        result: result,
                        searchQuery: viewModel.searchQuery,
                        onTap: {
                            viewModel.selectResult(result)
                        }
                    )
                }
            }
            .padding(.bottom)
        }
    }
}

// MARK: - Search Result Row

struct SearchResultRow: View {
    let result: SearchResult
    let searchQuery: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // Document name and page
                HStack {
                    Image(systemName: "doc.text")
                        .font(.caption)
                        .foregroundColor(.blue)

                    Text(result.documentName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)

                    Text("• Page \(result.pageNumber)")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()
                }

                // Context with highlighted match
                Text(highlightedContext)
                    .font(.caption)
                    .lineLimit(3)
                    .foregroundColor(.primary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
        }
        .padding(.horizontal)
    }

    private var highlightedContext: AttributedString {
        var attributed = AttributedString(result.context)

        // Highlight the search query
        if let range = attributed.range(of: searchQuery, options: .caseInsensitive) {
            attributed[range].backgroundColor = .yellow.opacity(0.3)
            attributed[range].font = .caption.bold()
        }

        return attributed
    }
}

// MARK: - Hybrid Search Result Row

struct HybridSearchResultRow: View {
    let result: HybridSearchResult
    let searchQuery: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // Document name, page, and relevance
                HStack {
                    Image(systemName: "doc.text")
                        .font(.caption)
                        .foregroundColor(.blue)

                    Text(result.documentName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)

                    Text("• Page \(result.pageNumber)")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    // Relevance badge
                    Text("\(result.relevanceScore)%")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(result.relevanceColor).opacity(0.2))
                        .foregroundColor(Color(result.relevanceColor))
                        .cornerRadius(4)
                }

                // Context with highlighted match
                Text(highlightedContext)
                    .font(.caption)
                    .lineLimit(3)
                    .foregroundColor(.primary)

                // Relevance label for semantic/hybrid
                if result.searchMode == .semantic || result.searchMode == .hybrid {
                    Text(result.relevanceLabel)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
        }
        .padding(.horizontal)
    }

    private var highlightedContext: AttributedString {
        var attributed = AttributedString(result.text)

        // Highlight the search query
        if let range = attributed.range(of: searchQuery, options: .caseInsensitive) {
            attributed[range].backgroundColor = .yellow.opacity(0.3)
            attributed[range].font = .caption.bold()
        }

        return attributed
    }
}

// MARK: - ViewModel

@MainActor
class DocumentSearchViewModel: ObservableObject {
    @Published var searchQuery: String = ""
    @Published var searchResults: [HybridSearchResult] = []
    @Published var isSearching: Bool = false
    @Published var selectedResult: HybridSearchResult?
    @Published var searchMode: SearchMode = .hybrid

    private let semanticSearchService = SemanticSearchService.shared
    private var searchTask: Task<Void, Never>?

    init() {
        // Debounce search
        $searchQuery
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] query in
                self?.performSearch(query: query)
            }
            .store(in: &cancellables)

        // Re-search when mode changes
        $searchMode
            .dropFirst() // Skip initial value
            .sink { [weak self] _ in
                if let query = self?.searchQuery, !query.isEmpty {
                    self?.performSearch(query: query)
                }
            }
            .store(in: &cancellables)
    }

    private var cancellables = Set<AnyCancellable>()

    func performSearch(query: String) {
        // Cancel previous search
        searchTask?.cancel()

        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            searchResults = []
            return
        }

        isSearching = true

        searchTask = Task {
            do {
                let results = try await semanticSearchService.search(
                    query: query,
                    documentIds: nil,
                    searchMode: searchMode
                )

                if !Task.isCancelled {
                    searchResults = results
                    isSearching = false

                    // Track statistics
                    UsageStatisticsService.shared.recordSearch()
                }
            } catch {
                if !Task.isCancelled {
                    searchResults = []
                    isSearching = false
                    print("Search error: \(error)")
                }
            }
        }
    }

    func clearSearch() {
        searchQuery = ""
        searchResults = []
    }

    func selectResult(_ result: SearchResult) {
        selectedResult = result
        // TODO: Navigate to document and highlight the match
    }
}

import Combine

struct DocumentSearchView_Previews: PreviewProvider {
    static var previews: some View {
        DocumentSearchView()
    }
}
