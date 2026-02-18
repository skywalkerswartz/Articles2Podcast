import Foundation
import AVFoundation
import os.log

private let logger = Logger(subsystem: "com.lukeswartz.articles2podcast", category: "TTS")

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
        let writer = SpeechWriter()
        return try await writer.synthesize(text: text, voiceId: voiceId)
    }
}

/// Encapsulates AVSpeechSynthesizer.write() with proper continuation safety and timeout.
private final class SpeechWriter: NSObject, AVSpeechSynthesizerDelegate, @unchecked Sendable {
    private let synthesizer = AVSpeechSynthesizer()
    private var audioFile: AVAudioFile?
    private var outputURL: URL?
    private var continuation: CheckedContinuation<URL, any Error>?
    private var hasResumed = false
    private var timeoutTask: Task<Void, Never>?

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func synthesize(text: String, voiceId: String) async throws -> URL {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(identifier: voiceId)
            ?? AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + ".caf")
        self.outputURL = url

        return try await withCheckedThrowingContinuation { cont in
            self.continuation = cont

            // Start a 60-second timeout
            self.timeoutTask = Task { [weak self] in
                try? await Task.sleep(for: .seconds(60))
                self?.resumeOnce(with: .failure(SpeechError.timeout))
            }

            self.synthesizer.write(utterance) { [weak self] buffer in
                guard let self, !self.hasResumed else { return }
                guard let pcmBuffer = buffer as? AVAudioPCMBuffer else { return }

                if pcmBuffer.frameLength == 0 {
                    // Synthesis complete
                    self.timeoutTask?.cancel()
                    self.resumeOnce(with: .success(url))
                    return
                }

                do {
                    if self.audioFile == nil {
                        self.audioFile = try AVAudioFile(
                            forWriting: url,
                            settings: pcmBuffer.format.settings,
                            commonFormat: .pcmFormatInt16,
                            interleaved: false
                        )
                    }
                    try self.audioFile?.write(from: pcmBuffer)
                } catch {
                    self.timeoutTask?.cancel()
                    self.resumeOnce(with: .failure(error))
                }
            }
        }
    }

    private func resumeOnce(with result: Result<URL, any Error>) {
        guard !hasResumed else { return }
        hasResumed = true
        switch result {
        case .success(let url): continuation?.resume(returning: url)
        case .failure(let error): continuation?.resume(throwing: error)
        }
    }

    // Delegate: handle unexpected cancellation
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        timeoutTask?.cancel()
        resumeOnce(with: .failure(SpeechError.cancelled))
    }

    enum SpeechError: LocalizedError {
        case timeout
        case cancelled

        var errorDescription: String? {
            switch self {
            case .timeout: "Speech synthesis timed out. Try again or switch TTS engine."
            case .cancelled: "Speech synthesis was cancelled."
            }
        }
    }
}

// MARK: - Kokoro TTS

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
