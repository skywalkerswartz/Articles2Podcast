import SwiftUI

struct VoiceSelectionView: View {
    @AppStorage("ttsEngine") private var ttsEngine: String = TTSEngine.appleSpeech.rawValue
    @AppStorage("voiceId") private var voiceId: String = ""

    private var voices: [TTSVoice] {
        let engine = TTSEngine(rawValue: ttsEngine) ?? .appleSpeech
        switch engine {
        case .kokoro:
            return KokoroTTSService().availableVoices
        case .appleSpeech:
            return AppleTTSService().availableVoices
        }
    }

    var body: some View {
        List {
            ForEach(voices) { voice in
                HStack {
                    VStack(alignment: .leading) {
                        Text(voice.name)
                            .font(.body)
                        Text(voice.language)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    if voiceId == voice.id {
                        Image(systemName: "checkmark")
                            .foregroundStyle(.blue)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    voiceId = voice.id
                }
            }
        }
        .navigationTitle("Voice Selection")
    }
}
