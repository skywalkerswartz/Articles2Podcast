import Foundation
import AVFoundation

// MARK: - Protocol

protocol TTSService: Sendable {
    var engineType: TTSEngine { get }
    var availableVoices: [TTSVoice] { get }
    var isModelLoaded: Bool { get }
    func loadModel() async throws
    func synthesize(text: String, voiceId: String) async throws -> URL
}

// MARK: - Apple Speech TTS

final class AppleTTSService: TTSService, @unchecked Sendable {
    let engineType: TTSEngine = .appleSpeech
    private let synthesizer = AVSpeechSynthesizer()

    var isModelLoaded: Bool { true }

    func loadModel() async throws {
        // No model to load for Apple Speech
    }

    var availableVoices: [TTSVoice] {
        AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language.hasPrefix("en") }
            .sorted { $0.quality.rawValue > $1.quality.rawValue }
            .map { voice in
                TTSVoice(
                    id: voice.identifier,
                    name: voice.name,
                    language: voice.language,
                    engine: .appleSpeech
                )
            }
    }

    func synthesize(text: String, voiceId: String) async throws -> URL {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(identifier: voiceId)
            ?? AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate

        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + ".caf")

        var audioFile: AVAudioFile?

        return try await withCheckedThrowingContinuation { continuation in
            synthesizer.write(utterance) { buffer in
                guard let pcmBuffer = buffer as? AVAudioPCMBuffer else { return }

                if pcmBuffer.frameLength == 0 {
                    // Synthesis complete
                    continuation.resume(returning: outputURL)
                    return
                }

                do {
                    if audioFile == nil {
                        audioFile = try AVAudioFile(
                            forWriting: outputURL,
                            settings: pcmBuffer.format.settings,
                            commonFormat: .pcmFormatInt16,
                            interleaved: false
                        )
                    }
                    try audioFile?.write(from: pcmBuffer)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

// MARK: - Kokoro TTS (Placeholder — requires KokoroSwift integration)

final class KokoroTTSService: TTSService, @unchecked Sendable {
    let engineType: TTSEngine = .kokoro
    private let fileManager = AudioFileManager.shared
    private var _isModelLoaded = false

    var isModelLoaded: Bool { _isModelLoaded }

    var availableVoices: [TTSVoice] {
        [
            TTSVoice(id: "af_heart", name: "Heart", language: "en-US", engine: .kokoro),
            TTSVoice(id: "af_bella", name: "Bella", language: "en-US", engine: .kokoro),
            TTSVoice(id: "af_nova", name: "Nova", language: "en-US", engine: .kokoro),
            TTSVoice(id: "af_sarah", name: "Sarah", language: "en-US", engine: .kokoro),
            TTSVoice(id: "am_adam", name: "Adam", language: "en-US", engine: .kokoro),
            TTSVoice(id: "am_michael", name: "Michael", language: "en-US", engine: .kokoro),
            TTSVoice(id: "bf_emma", name: "Emma", language: "en-GB", engine: .kokoro),
            TTSVoice(id: "bm_daniel", name: "Daniel", language: "en-GB", engine: .kokoro),
        ]
    }

    func loadModel() async throws {
        let modelPath = fileManager.modelsDirectory.appendingPathComponent("kokoro-v1_0.safetensors")
        guard FileManager.default.fileExists(atPath: modelPath.path) else {
            throw KokoroError.modelNotFound
        }
        // TODO: Initialize KokoroTTS with model path
        // let tts = KokoroTTS(modelPath: modelPath.path, g2p: .misaki)
        _isModelLoaded = true
    }

    func synthesize(text: String, voiceId: String) async throws -> URL {
        guard isModelLoaded else {
            throw KokoroError.modelNotLoaded
        }

        // TODO: Implement actual Kokoro synthesis
        // let audioBuffer = try tts.generateAudio(voice: voiceEmbedding, language: .enUS, text: text)
        // Convert buffer to M4A and return URL

        // For now, fall back to Apple Speech
        let fallback = AppleTTSService()
        return try await fallback.synthesize(text: text, voiceId: "")
    }

    enum KokoroError: LocalizedError {
        case modelNotFound
        case modelNotLoaded
        case synthesizeFailed

        var errorDescription: String? {
            switch self {
            case .modelNotFound: "Kokoro model not found. Please download it in Settings."
            case .modelNotLoaded: "Kokoro model is not loaded."
            case .synthesizeFailed: "Audio synthesis failed."
            }
        }
    }
}
