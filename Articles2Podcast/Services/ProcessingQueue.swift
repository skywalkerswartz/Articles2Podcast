import Foundation
import SwiftData
import Observation
import os.log

@Observable
@MainActor
final class ProcessingQueue {
    static let shared = ProcessingQueue()
    private let logger = Logger(subsystem: "com.lukeswartz.articles2podcast", category: "Processing")
    private let extractor = ArticleExtractor()
    private let audioGen = AudioGenerationService.shared

    var isProcessing = false

    private init() {}

    func processArticle(_ article: Article, in context: ModelContext) async {
        guard article.state == .pendingExtraction || article.state.canRetry else { return }

        isProcessing = true
        defer { isProcessing = false }

        // Phase 1: Extract
        await extractArticle(article, context: context)

        // Phase 2: Generate audio (if extraction succeeded)
        if article.state == .extracted {
            await generateAudio(for: article, context: context)
        }
    }

    func processNextArticle() async {
        // Called from background processing; creates its own context
        let container = SharedModelContainer.create()
        let context = ModelContext(container)

        let descriptor = FetchDescriptor<Article>(
            predicate: #Predicate<Article> { $0.stateRawValue == 0 },
            sortBy: [SortDescriptor(\.sortOrder)]
        )

        guard let article = try? context.fetch(descriptor).first else { return }
        await processArticle(article, in: context)
    }

    private func extractArticle(_ article: Article, context: ModelContext) async {
        article.state = .extracting
        trySave(context)

        do {
            guard let url = URL(string: article.url) else {
                throw ArticleExtractor.ExtractionError.invalidURL
            }

            let extracted = try await extractor.extract(from: url)

            article.title = extracted.title
            article.author = extracted.author
            article.excerpt = extracted.excerpt
            article.extractedText = extracted.content
            article.wordCount = extracted.content.split(separator: " ").count
            article.state = .extracted
            article.extractedAt = Date()
            article.errorMessage = nil

            trySave(context)
            logger.info("Extracted article: \(article.title)")
        } catch {
            article.state = .extractionFailed
            article.errorMessage = error.localizedDescription
            article.retryCount += 1
            trySave(context)
            logger.error("Extraction failed: \(error.localizedDescription)")
        }
    }

    private func generateAudio(for article: Article, context: ModelContext) async {
        guard let text = article.extractedText, !text.isEmpty else {
            article.state = .audioGenerationFailed
            article.errorMessage = "No extracted text available."
            trySave(context)
            return
        }

        article.state = .generatingAudio
        let paragraphs = TextCleaner.splitIntoParagraphs(text)
        article.totalParagraphs = paragraphs.count
        article.processedParagraphs = 0
        trySave(context)

        let engine = TTSEngine(rawValue: UserDefaults.standard.string(forKey: "ttsEngine") ?? "apple_speech") ?? .appleSpeech
        let voiceId = UserDefaults.standard.string(forKey: "voiceId") ?? ""

        do {
            let articleId = article.id
            let result = try await audioGen.generateAudio(
                for: articleId,
                text: text,
                engine: engine,
                voiceId: voiceId,
                onProgress: { @MainActor processed, total in
                    article.processedParagraphs = processed
                }
            )

            article.audioFilePath = result.url.lastPathComponent
            article.audioDurationSeconds = result.duration
            article.state = .audioReady
            article.audioGeneratedAt = Date()
            article.errorMessage = nil

            trySave(context)
            logger.info("Audio generated for: \(article.title)")
        } catch {
            article.state = .audioGenerationFailed
            article.errorMessage = error.localizedDescription
            article.retryCount += 1
            trySave(context)
            logger.error("Audio generation failed: \(error.localizedDescription)")
        }
    }

    private func trySave(_ context: ModelContext) {
        do {
            try context.save()
        } catch {
            logger.error("Failed to save context: \(error.localizedDescription)")
        }
    }
}
