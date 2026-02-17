import Foundation

enum ArticleState: Int, Codable, CaseIterable, Sendable {
    case pendingExtraction = 0
    case extracting = 1
    case extractionFailed = 2
    case extracted = 3
    case generatingAudio = 4
    case audioGenerationFailed = 5
    case audioReady = 6
    case playing = 7
    case played = 8

    var displayName: String {
        switch self {
        case .pendingExtraction: "Waiting"
        case .extracting: "Extracting..."
        case .extractionFailed: "Extraction Failed"
        case .extracted: "Extracted"
        case .generatingAudio: "Generating Audio..."
        case .audioGenerationFailed: "Audio Failed"
        case .audioReady: "Ready"
        case .playing: "Playing"
        case .played: "Played"
        }
    }

    var systemImage: String {
        switch self {
        case .pendingExtraction: "clock"
        case .extracting: "arrow.down.circle"
        case .extractionFailed: "exclamationmark.triangle"
        case .extracted: "doc.text"
        case .generatingAudio: "waveform"
        case .audioGenerationFailed: "exclamationmark.triangle"
        case .audioReady: "checkmark.circle.fill"
        case .playing: "play.circle.fill"
        case .played: "checkmark.circle"
        }
    }

    var isError: Bool {
        self == .extractionFailed || self == .audioGenerationFailed
    }

    var isProcessing: Bool {
        self == .extracting || self == .generatingAudio
    }

    var canRetry: Bool {
        isError
    }

    var canPlay: Bool {
        self == .audioReady || self == .playing || self == .played
    }
}
