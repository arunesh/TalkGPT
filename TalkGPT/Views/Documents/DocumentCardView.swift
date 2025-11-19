//
//  DocumentCardView.swift
//  TalkGPT
//
//  Created by TalkGPT on 2025-11-19.
//

import SwiftUI

struct DocumentCardView: View {
    let document: Document
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            // Thumbnail
            thumbnailView
                .frame(width: 80, height: 100)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)

            // Document Info
            VStack(alignment: .leading, spacing: 6) {
                Text(document.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(2)

                HStack(spacing: 4) {
                    Image(systemName: "doc.text")
                        .font(.caption)
                    Text("\(document.pageCount) page\(document.pageCount == 1 ? "" : "s")")
                        .font(.caption)
                }
                .foregroundColor(.secondary)

                HStack(spacing: 4) {
                    Image(systemName: "character.textbox")
                        .font(.caption)
                    Text("\(document.totalCharacters) characters")
                        .font(.caption)
                }
                .foregroundColor(.secondary)

                Text(formattedDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Actions
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
                    .padding(8)
            }
            .buttonStyle(BorderlessButtonStyle())
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }

    // MARK: - Subviews

    @ViewBuilder
    private var thumbnailView: some View {
        if let thumbnailURL = document.thumbnailURL,
           let uiImage = UIImage(contentsOfFile: thumbnailURL.path) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .clipped()
        } else {
            VStack {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var formattedDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: document.createdDate, relativeTo: Date())
    }
}

// MARK: - Preview

struct DocumentCardView_Previews: PreviewProvider {
    static var previews: some View {
        DocumentCardView(
            document: Document(
                name: "Sample Document",
                fileURL: URL(fileURLWithPath: "/sample.pdf"),
                pageCount: 5,
                totalCharacters: 2500
            ),
            onDelete: {}
        )
        .previewLayout(.sizeThatFits)
        .padding()
    }
}
