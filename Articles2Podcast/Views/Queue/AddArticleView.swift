import SwiftUI
import SwiftData

struct AddArticleView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(ProcessingQueue.self) private var processingQueue
    @State private var urlString = ""
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Article URL", text: $urlString)
                        .keyboardType(.URL)
                        .textContentType(.URL)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()

                    Button {
                        pasteFromClipboard()
                    } label: {
                        Label("Paste from Clipboard", systemImage: "doc.on.clipboard")
                    }
                } header: {
                    Text("URL")
                } footer: {
                    if let error = errorMessage {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Add Article")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { addArticle() }
                        .disabled(urlString.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func pasteFromClipboard() {
        if let string = UIPasteboard.general.string {
            urlString = string.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    private func addArticle() {
        var trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)

        // Add https:// if no scheme
        if !trimmed.contains("://") {
            trimmed = "https://" + trimmed
        }

        guard let url = URL(string: trimmed), url.scheme != nil, url.host() != nil else {
            errorMessage = "Please enter a valid URL."
            return
        }

        let descriptor = FetchDescriptor<Article>(
            sortBy: [SortDescriptor(\Article.sortOrder, order: .reverse)]
        )
        let maxOrder = (try? modelContext.fetch(descriptor))?.first?.sortOrder ?? 0

        let article = Article(url: trimmed, sortOrder: maxOrder + 100)
        modelContext.insert(article)
        try? modelContext.save()

        // Start processing
        Task {
            await processingQueue.processArticle(article, in: modelContext)
        }

        dismiss()
    }
}
