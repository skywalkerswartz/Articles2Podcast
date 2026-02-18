import Foundation
import AVFoundation
import os.log

actor AudioGenerationService {
    static let shared = AudioGenerationService()
    private let logger = Logger(subsystem: "com.lukeswartz.articles2podcast", category: "AudioGen")
    private let fileManager = AudioFileManager.shared

    func generateAudio(
        for articleId: UUID,
        text: String,
        engine: TTSEngine,
        voiceId: String,
        onProgress: @MainActor @Sendable @escaping (Int, Int) -> Void
    ) async throws -> (url: URL, duration: Double) {
        var ttsService: TTSService = switch engine {
        case .kokoro: KokoroTTSService()
        case .appleSpeech: AppleTTSService()
        }

        // If the selected engine's model isn't available, fall back to Apple Speech
        if !ttsService.isModelLoaded {
            do {
                try await ttsService.loadModel()
            } catch {
                logger.warning("Failed to load \(engine.displayName) model, falling back to Apple Speech: \(error.localizedDescription)")
                ttsService = AppleTTSService()
            }
        }

        let paragraphs = TextCleaner.splitIntoParagraphs(text)
        guard !paragraphs.isEmpty else {
            throw GenerationError.emptyText
        }

        let totalParagraphs = paragraphs.count
        var paragraphURLs: [URL] = []

        for (index, paragraph) in paragraphs.enumerated() {
            let rawURL = try await ttsService.synthesize(text: paragraph, voiceId: voiceId)
            let destURL = fileManager.paragraphFileURL(for: articleId, index: index)

            // Convert CAF/raw audio to M4A so AVMutableComposition can read it
            let m4aURL = try await convertToM4A(source: rawURL, destination: destURL)
            paragraphURLs.append(m4aURL)

            // Clean up the raw temp file
            try? FileManager.default.removeItem(at: rawURL)

            await onProgress(index + 1, totalParagraphs)
            logger.info("Generated paragraph \(index + 1)/\(totalParagraphs)")
        }

        // Concatenate into single M4A file
        let outputURL = fileManager.audioFileURL(for: articleId)
        let duration = try await concatenateAudioFiles(paragraphURLs, to: outputURL)

        // Clean up paragraph files
        try? FileManager.default.removeItem(at: fileManager.paragraphDirectory(for: articleId))

        return (outputURL, duration)
    }

    /// Converts a raw audio file (CAF, WAV, etc.) to M4A (AAC) format
    private func convertToM4A(source: URL, destination: URL) async throws -> URL {
        // Ensure destination has .m4a extension
        let m4aURL = destination.deletingPathExtension().appendingPathExtension("m4a")

        if FileManager.default.fileExists(atPath: m4aURL.path) {
            try FileManager.default.removeItem(at: m4aURL)
        }

        let asset = AVURLAsset(url: source)
        guard let exportSession = AVAssetExportSession(
            asset: asset,
            presetName: AVAssetExportPresetAppleM4A
        ) else {
            // If export session can't be created, try direct copy as fallback
            try FileManager.default.moveItem(at: source, to: m4aURL)
            return m4aURL
        }

        exportSession.outputURL = m4aURL
        exportSession.outputFileType = .m4a

        await exportSession.export()

        if let error = exportSession.error {
            throw error
        }

        return m4aURL
    }

    private func concatenateAudioFiles(_ files: [URL], to outputURL: URL) async throws -> Double {
        let composition = AVMutableComposition()
        guard let audioTrack = composition.addMutableTrack(
            withMediaType: .audio,
            preferredTrackID: kCMPersistentTrackID_Invalid
        ) else {
            throw GenerationError.compositionFailed
        }

        var currentTime = CMTime.zero

        for fileURL in files {
            let asset = AVURLAsset(url: fileURL)
            let assetDuration: CMTime
            let tracks: [AVAssetTrack]

            assetDuration = try await asset.load(.duration)
            tracks = try await asset.loadTracks(withMediaType: .audio)

            guard let sourceTrack = tracks.first else { continue }

            let timeRange = CMTimeRange(start: .zero, duration: assetDuration)
            try audioTrack.insertTimeRange(timeRange, of: sourceTrack, at: currentTime)
            currentTime = CMTimeAdd(currentTime, assetDuration)
        }

        // Export to M4A
        if FileManager.default.fileExists(atPath: outputURL.path) {
            try FileManager.default.removeItem(at: outputURL)
        }

        guard let exportSession = AVAssetExportSession(
            asset: composition,
            presetName: AVAssetExportPresetAppleM4A
        ) else {
            throw GenerationError.exportFailed
        }

        exportSession.outputURL = outputURL
        exportSession.outputFileType = .m4a

        await exportSession.export()

        if let error = exportSession.error {
            throw error
        }

        let duration = CMTimeGetSeconds(currentTime)
        return duration
    }

    enum GenerationError: LocalizedError {
        case emptyText
        case compositionFailed
        case exportFailed

        var errorDescription: String? {
            switch self {
            case .emptyText: "No text to generate audio from."
            case .compositionFailed: "Failed to create audio composition."
            case .exportFailed: "Failed to export audio file."
            }
        }
    }
}
