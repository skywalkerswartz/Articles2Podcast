import SwiftUI

struct MiniPlayerView: View {
    @Environment(AudioPlayerService.self) private var audioPlayer

    var body: some View {
        VStack(spacing: 0) {
            // Progress bar
            GeometryReader { geometry in
                Rectangle()
                    .fill(.blue)
                    .frame(width: geometry.size.width * audioPlayer.progress)
            }
            .frame(height: 2)

            HStack(spacing: 12) {
                // Article info
                VStack(alignment: .leading, spacing: 2) {
                    Text(audioPlayer.currentArticleTitle ?? "")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)

                    Text(audioPlayer.currentArticleDomain ?? "")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                // Play/Pause button
                Button {
                    audioPlayer.togglePlayPause()
                } label: {
                    Image(systemName: audioPlayer.isPlaying ? "pause.fill" : "play.fill")
                        .font(.title3)
                        .frame(width: 44, height: 44)
                }

                // Skip forward
                Button {
                    audioPlayer.skipForward()
                } label: {
                    Image(systemName: "goforward.30")
                        .font(.body)
                        .frame(width: 36, height: 36)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(.ultraThinMaterial)
        .contentShape(Rectangle())
        .onTapGesture {
            audioPlayer.showFullPlayer = true
        }
    }
}
