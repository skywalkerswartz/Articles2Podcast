import SwiftUI

struct ModelManagementView: View {
    @State private var modelManager = ModelDownloadManager.shared
    @State private var showDeleteConfirmation = false

    var body: some View {
        Form {
            Section("Kokoro TTS Model") {
                if modelManager.isKokoroModelDownloaded {
                    HStack {
                        Label("Downloaded", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Spacer()
                        Text(modelManager.kokoroModelSize)
                            .foregroundStyle(.secondary)
                    }

                    Button("Delete Model", role: .destructive) {
                        showDeleteConfirmation = true
                    }
                } else if modelManager.isDownloading {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Downloading...")
                            Spacer()
                            Text("\(Int(modelManager.downloadProgress * 100))%")
                                .monospacedDigit()
                        }

                        ProgressView(value: modelManager.downloadProgress)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Model not downloaded")
                        Text("~330 MB download required for Kokoro TTS")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Button {
                        Task {
                            await modelManager.downloadKokoroModel()
                        }
                    } label: {
                        Label("Download Model", systemImage: "arrow.down.circle")
                    }
                }

                if let error = modelManager.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            Section {
                Text("The Kokoro model provides high-quality neural text-to-speech with multiple voice options. Audio is generated entirely on-device.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Model Management")
        .confirmationDialog(
            "Delete Kokoro Model?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                modelManager.deleteKokoroModel()
            }
        } message: {
            Text("You can re-download it later from Settings.")
        }
    }
}
