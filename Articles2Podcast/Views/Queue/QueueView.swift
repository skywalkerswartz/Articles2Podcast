import SwiftUI
import SwiftData

struct QueueView: View {
    @Query(sort: \Article.sortOrder) private var articles: [Article]
    @Environment(\.modelContext) private var modelContext
    @Environment(ProcessingQueue.self) private var processingQueue
    @Environment(AudioPlayerService.self) private var audioPlayer
    @State private var showAddArticle = false

    var body: some View {
        Group {
            if articles.isEmpty {
                ContentUnavailableView(
                    "No Articles",
                    systemImage: "doc.text",
                    description: Text("Add an article URL to get started, or share a link from Safari.")
                )
            } else {
                List {
                    ForEach(articles) { article in
                        QueueRowView(article: article)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                handleArticleTap(article)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    deleteArticle(article)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .leading) {
                                if article.state.canRetry {
                                    Button {
                                        retryArticle(article)
                                    } label: {
                                        Label("Retry", systemImage: "arrow.clockwise")
                                    }
                                    .tint(.orange)
                                }
                            }
                    }
                    .onMove(perform: moveArticles)
                }
            }
        }
        .navigationTitle("Queue")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddArticle = true
                } label: {
                    Image(systemName: "plus")
                }
            }
            ToolbarItem(placement: .topBarLeading) {
                if !articles.isEmpty {
                    EditButton()
                }
            }
        }
        .sheet(isPresented: $showAddArticle) {
            AddArticleView()
        }
        .task {
            await processNewArticles()
        }
    }

    private func handleArticleTap(_ article: Article) {
        guard article.state.canPlay else { return }

        let fileURL = AudioFileManager.shared.audioFileURL(for: article.id)
        do {
            try audioPlayer.loadArticle(
                id: article.id,
                title: article.title,
                domain: article.domain,
                fileURL: fileURL,
                resumeFrom: article.playbackPosition
            )
            audioPlayer.play()
            article.state = .playing
            article.lastPlayedAt = Date()
            try? modelContext.save()
        } catch {
            print("Failed to load article audio: \(error)")
        }
    }

    private func deleteArticle(_ article: Article) {
        AudioFileManager.shared.deleteAudioFile(for: article.id)
        modelContext.delete(article)
        try? modelContext.save()
    }

    private func retryArticle(_ article: Article) {
        article.state = .pendingExtraction
        article.errorMessage = nil
        try? modelContext.save()
        Task {
            await processingQueue.processArticle(article, in: modelContext)
        }
    }

    private func moveArticles(from source: IndexSet, to destination: Int) {
        var mutableArticles = articles
        mutableArticles.move(fromOffsets: source, toOffset: destination)
        for (index, article) in mutableArticles.enumerated() {
            article.sortOrder = index * 100
        }
        try? modelContext.save()
    }

    private func processNewArticles() async {
        // Reset any articles stuck in intermediate processing states (from previous crash/kill)
        let stuck = articles.filter { $0.state == .extracting || $0.state == .generatingAudio }
        for article in stuck {
            article.state = .pendingExtraction
            article.errorMessage = nil
        }
        if !stuck.isEmpty {
            try? modelContext.save()
        }

        let pending = articles.filter { $0.state == .pendingExtraction }
        for article in pending {
            await processingQueue.processArticle(article, in: modelContext)
        }
    }
}
