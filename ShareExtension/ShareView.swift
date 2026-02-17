@preconcurrency import Foundation
import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ShareView: View {
    var extensionContext: NSExtensionContext?
    @Environment(\.modelContext) private var modelContext
    @State private var url = ""
    @State private var title = ""
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading...")
                } else {
                    Form {
                        Section("Article") {
                            if !title.isEmpty {
                                Text(title)
                                    .font(.headline)
                            }
                            Text(url)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                    }
                }
            }
            .navigationTitle("Add to Queue")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        extensionContext?.completeRequest(returningItems: nil)
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveArticle()
                    }
                    .disabled(url.isEmpty)
                }
            }
        }
        .task {
            await extractURL()
            isLoading = false
        }
    }

    private func saveArticle() {
        let descriptor = FetchDescriptor<Article>(
            sortBy: [SortDescriptor(\Article.sortOrder, order: .reverse)]
        )
        let maxOrder = (try? modelContext.fetch(descriptor))?.first?.sortOrder ?? 0

        let article = Article(url: url, title: title, sortOrder: maxOrder + 100)
        modelContext.insert(article)
        try? modelContext.save()

        extensionContext?.completeRequest(returningItems: nil)
    }

    private func extractURL() async {
        guard let items = extensionContext?.inputItems as? [NSExtensionItem] else { return }

        for item in items {
            guard let attachments = item.attachments else { continue }
            for provider in attachments {
                if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                    if let urlItem = try? await provider.loadItem(
                        forTypeIdentifier: UTType.url.identifier
                    ) as? URL {
                        url = urlItem.absoluteString
                        title = item.attributedContentText?.string ?? urlItem.host() ?? ""
                    }
                } else if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                    if let text = try? await provider.loadItem(
                        forTypeIdentifier: UTType.plainText.identifier
                    ) as? String, text.hasPrefix("http") {
                        url = text
                    }
                }
            }
        }
    }
}
