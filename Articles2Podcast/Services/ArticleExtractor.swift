import Foundation
import Readability

struct ExtractedArticle: Sendable {
    let title: String
    let author: String?
    let content: String
    let excerpt: String?
}

@MainActor
final class ArticleExtractor {
    private let readability = Readability()

    func extract(from url: URL) async throws -> ExtractedArticle {
        let result = try await readability.parse(url: url)

        let cleanedContent = TextCleaner.clean(result.content ?? "")

        guard !cleanedContent.isEmpty else {
            throw ExtractionError.noContent
        }

        return ExtractedArticle(
            title: result.title ?? url.host(percentEncoded: false) ?? "Untitled",
            author: result.byline,
            content: cleanedContent,
            excerpt: result.excerpt
        )
    }

    enum ExtractionError: LocalizedError {
        case noContent
        case invalidURL

        var errorDescription: String? {
            switch self {
            case .noContent: "Could not extract article content from this page."
            case .invalidURL: "The URL is not valid."
            }
        }
    }
}
