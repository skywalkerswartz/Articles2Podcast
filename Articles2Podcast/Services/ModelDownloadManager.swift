import Foundation
import Observation
import os.log

@Observable
@MainActor
final class ModelDownloadManager {
    static let shared = ModelDownloadManager()

    private let logger = Logger(subsystem: "com.lukeswartz.articles2podcast", category: "ModelDownload")
    private let fileManager = AudioFileManager.shared

    var isDownloading = false
    var downloadProgress: Double = 0
    var errorMessage: String?

    private let kokoroModelURL = URL(string: "https://huggingface.co/hexgrad/Kokoro-82M/resolve/main/kokoro-v1_0.safetensors")!
    private let kokoroModelFilename = "kokoro-v1_0.safetensors"

    var isKokoroModelDownloaded: Bool {
        let path = fileManager.modelsDirectory.appendingPathComponent(kokoroModelFilename)
        return FileManager.default.fileExists(atPath: path.path)
    }

    var kokoroModelSize: String {
        let path = fileManager.modelsDirectory.appendingPathComponent(kokoroModelFilename)
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: path.path),
              let size = attrs[.size] as? Int64 else { return "~330 MB" }
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }

    func downloadKokoroModel() async {
        guard !isDownloading else { return }

        isDownloading = true
        downloadProgress = 0
        errorMessage = nil

        do {
            let destination = fileManager.modelsDirectory.appendingPathComponent(kokoroModelFilename)

            let (tempURL, _) = try await URLSession.shared.download(from: kokoroModelURL) { [weak self] progress in
                Task { @MainActor in
                    self?.downloadProgress = progress
                }
            }

            if FileManager.default.fileExists(atPath: destination.path) {
                try FileManager.default.removeItem(at: destination)
            }
            try FileManager.default.moveItem(at: tempURL, to: destination)

            // Exclude from backup
            var mutableURL = destination
            var resourceValues = URLResourceValues()
            resourceValues.isExcludedFromBackup = true
            try mutableURL.setResourceValues(resourceValues)

            logger.info("Kokoro model downloaded successfully")
        } catch {
            errorMessage = error.localizedDescription
            logger.error("Model download failed: \(error.localizedDescription)")
        }

        isDownloading = false
    }

    func deleteKokoroModel() {
        let path = fileManager.modelsDirectory.appendingPathComponent(kokoroModelFilename)
        try? FileManager.default.removeItem(at: path)
    }
}

// MARK: - URLSession download with progress

extension URLSession {
    func download(from url: URL, progressHandler: @escaping @Sendable (Double) -> Void) async throws -> (URL, URLResponse) {
        try await withCheckedThrowingContinuation { continuation in
            let task = self.downloadTask(with: url) { tempURL, response, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let tempURL, let response else {
                    continuation.resume(throwing: URLError(.badServerResponse))
                    return
                }
                // Move to a stable temp location since the task's temp file is deleted
                let stableTemp = FileManager.default.temporaryDirectory
                    .appendingPathComponent(UUID().uuidString)
                do {
                    try FileManager.default.moveItem(at: tempURL, to: stableTemp)
                    continuation.resume(returning: (stableTemp, response))
                } catch {
                    continuation.resume(throwing: error)
                }
            }
            task.resume()
        }
    }
}
