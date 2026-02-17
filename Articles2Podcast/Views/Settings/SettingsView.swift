import SwiftUI

struct SettingsView: View {
    @AppStorage("ttsEngine") private var ttsEngine: String = TTSEngine.appleSpeech.rawValue
    @AppStorage("voiceId") private var voiceId: String = ""
    @AppStorage("autoPlay") private var autoPlay = true
    @AppStorage("autoDelete") private var autoDelete = false
    @AppStorage("allowCellular") private var allowCellular = true
    @AppStorage("defaultPlaybackSpeed") private var defaultPlaybackSpeed: Double = 1.0
    @State private var modelManager = ModelDownloadManager.shared

    private var selectedEngine: TTSEngine {
        TTSEngine(rawValue: ttsEngine) ?? .appleSpeech
    }

    var body: some View {
        Form {
            // TTS Engine
            Section("Text-to-Speech") {
                Picker("Engine", selection: $ttsEngine) {
                    ForEach(TTSEngine.allCases) { engine in
                        Text(engine.displayName).tag(engine.rawValue)
                    }
                }

                NavigationLink("Voice Selection") {
                    VoiceSelectionView()
                }

                if selectedEngine == .kokoro {
                    NavigationLink("Model Management") {
                        ModelManagementView()
                    }
                }
            }

            // Playback
            Section("Playback") {
                Toggle("Auto-play Next Article", isOn: $autoPlay)

                HStack {
                    Text("Default Speed")
                    Spacer()
                    Picker("Speed", selection: $defaultPlaybackSpeed) {
                        Text("0.5x").tag(0.5)
                        Text("0.75x").tag(0.75)
                        Text("1x").tag(1.0)
                        Text("1.25x").tag(1.25)
                        Text("1.5x").tag(1.5)
                        Text("1.75x").tag(1.75)
                        Text("2x").tag(2.0)
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                }
            }

            // Downloads
            Section("Downloads") {
                Toggle("Allow Cellular Downloads", isOn: $allowCellular)
                Toggle("Auto-delete After Listening", isOn: $autoDelete)
            }

            // Storage
            Section("Storage") {
                HStack {
                    Text("Audio Files")
                    Spacer()
                    Text(AudioFileManager.shared.formattedStorageUsed())
                        .foregroundStyle(.secondary)
                }

                Button("Clear All Downloads", role: .destructive) {
                    try? AudioFileManager.shared.deleteAllAudioFiles()
                }
            }

            // About
            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                        .foregroundStyle(.secondary)
                }

                Link("Source Code on GitHub", destination: URL(string: "https://github.com/lukeswartz/Articles2Podcast")!)
            }
        }
        .navigationTitle("Settings")
    }
}
