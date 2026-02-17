import Foundation
import os.log

final class AudioFileManager: @unchecked Sendable {
    static let shared = AudioFileManager()
    private let fileManager = FileManager.default
    private nonisolated(unsafe) let logger = Logger(subsystem: "com.lukeswartz.articles2podcast", category: "AudioFiles")

    var audioDirectory: URL {
        let appSupport = fileManager.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        let audioDir = appSupport.appendingPathComponent("Audio", isDirectory: true)
        if !fileManager.fileExists(atPath: audioDir.path) {
            try? fileManager.createDirectory(at: audioDir, withIntermediateDirectories: true)
        }
        return audioDir
    }

    var modelsDirectory: URL {
        let appSupport = fileManager.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        let modelsDir = appSupport.appendingPathComponent("Models", isDirectory: true)
        if !fileManager.fileExists(atPath: modelsDir.path) {
            try? fileManager.createDirectory(at: modelsDir, withIntermediateDirectories: true)
        }
        return modelsDir
    }

    func audioFileURL(for articleId: UUID) -> URL {
        audioDirectory.appendingPathComponent("\(articleId.uuidString).m4a")
    }

    func paragraphDirectory(for articleId: UUID) -> URL {
        let dir = audioDirectory.appendingPathComponent(articleId.uuidString, isDirectory: true)
        if !fileManager.fileExists(atPath: dir.path) {
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    func paragraphFileURL(for articleId: UUID, index: Int) -> URL {
        paragraphDirectory(for: articleId)
            .appendingPathComponent(String(format: "%03d.m4a", index))
    }

    func saveFile(from tempLocation: URL, to destination: URL) throws {
        if fileManager.fileExists(atPath: destination.path) {
            try fileManager.removeItem(at: destination)
        }
        try fileManager.moveItem(at: tempLocation, to: destination)
        excludeFromBackup(url: destination)
    }

    func deleteAudioFile(for articleId: UUID) {
        let fileURL = audioFileURL(for: articleId)
        let dirURL = paragraphDirectory(for: articleId)

        try? fileManager.removeItem(at: fileURL)
        try? fileManager.removeItem(at: dirURL)
    }

    func fileExists(for articleId: UUID) -> Bool {
        fileManager.fileExists(atPath: audioFileURL(for: articleId).path)
    }

    func totalStorageUsed() -> Int64 {
        guard let enumerator = fileManager.enumerator(
            at: audioDirectory,
            includingPropertiesForKeys: [.fileSizeKey],
            options: [.skipsHiddenFiles]
        ) else { return 0 }

        var totalSize: Int64 = 0
        for case let fileURL as URL in enumerator {
            if let values = try? fileURL.resourceValues(forKeys: [.fileSizeKey]),
               let size = values.fileSize {
                totalSize += Int64(size)
            }
        }
        return totalSize
    }

    func formattedStorageUsed() -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: totalStorageUsed())
    }

    func deleteAllAudioFiles() throws {
        if fileManager.fileExists(atPath: audioDirectory.path) {
            try fileManager.removeItem(at: audioDirectory)
            try fileManager.createDirectory(at: audioDirectory, withIntermediateDirectories: true)
        }
    }

    private func excludeFromBackup(url: URL) {
        var mutableURL = url
        var resourceValues = URLResourceValues()
        resourceValues.isExcludedFromBackup = true
        try? mutableURL.setResourceValues(resourceValues)
    }
}
