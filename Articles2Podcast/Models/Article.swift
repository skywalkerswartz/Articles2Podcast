import Foundation
import SwiftData

@Model
final class Article {
    @Attribute(.unique) var id: UUID
    var url: String
    var domain: String
    var title: String
    var author: String?
    var excerpt: String?

    @Attribute(.externalStorage)
    var extractedText: String?
    var wordCount: Int?

    var audioFilePath: String?
    var audioDurationSeconds: Double?

    var stateRawValue: Int
    var errorMessage: String?
    var retryCount: Int

    var playbackPosition: Double
    var playbackRate: Float
    var hasBeenPlayed: Bool

    var sortOrder: Int

    var createdAt: Date
    var extractedAt: Date?
    var audioGeneratedAt: Date?
    var lastPlayedAt: Date?

    var totalParagraphs: Int?
    var processedParagraphs: Int?

    var state: ArticleState {
        get { ArticleState(rawValue: stateRawValue) ?? .pendingExtraction }
        set { stateRawValue = newValue.rawValue }
    }

    var generationProgress: Double {
        guard let total = totalParagraphs, total > 0,
              let processed = processedParagraphs else { return 0 }
        return Double(processed) / Double(total)
    }

    init(url: String, title: String = "", sortOrder: Int = 0) {
        self.id = UUID()
        self.url = url
        self.domain = URL(string: url)?.host(percentEncoded: false) ?? ""
        self.title = title.isEmpty ? url : title
        self.stateRawValue = ArticleState.pendingExtraction.rawValue
        self.retryCount = 0
        self.playbackPosition = 0
        self.playbackRate = 1.0
        self.hasBeenPlayed = false
        self.sortOrder = sortOrder
        self.createdAt = Date()
    }
}
