import Foundation

enum TTSEngine: String, Codable, CaseIterable, Identifiable, Sendable {
    case kokoro = "kokoro"
    case appleSpeech = "apple_speech"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .kokoro: "Kokoro (On-Device AI)"
        case .appleSpeech: "Apple Speech"
        }
    }

    var description: String {
        switch self {
        case .kokoro: "High-quality neural TTS using the Kokoro model. Requires ~330MB model download."
        case .appleSpeech: "Built-in iOS speech synthesis. No download required."
        }
    }

    var requiresModelDownload: Bool {
        switch self {
        case .kokoro: true
        case .appleSpeech: false
        }
    }
}

struct TTSVoice: Identifiable, Sendable {
    let id: String
    let name: String
    let language: String
    let engine: TTSEngine

    var displayName: String {
        "\(name) (\(language))"
    }
}
