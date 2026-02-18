import SwiftUI

struct QueueRowView: View {
    let article: Article

    var body: some View {
        HStack(spacing: 12) {
            stateIcon
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(article.title)
                    .font(.headline)
                    .lineLimit(2)

                HStack(spacing: 6) {
                    Text(article.domain)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let duration = article.audioDurationSeconds {
                        Text("·")
                            .foregroundStyle(.secondary)
                        Text(formatDuration(duration))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if article.state.isError, let error = article.errorMessage {
                    Text(error)
                        .font(.caption2)
                        .foregroundStyle(.red)
                        .lineLimit(1)
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var stateIcon: some View {
        switch article.state {
        case .pendingExtraction:
            Image(systemName: "clock")
                .foregroundStyle(.secondary)
        case .extracting:
            DownloadProgressCircle(progress: nil)
        case .generatingAudio:
            let progress = article.generationProgress
            DownloadProgressCircle(progress: progress > 0 ? progress : nil)
        case .extractionFailed, .audioGenerationFailed:
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
        case .extracted:
            Image(systemName: "doc.text.fill")
                .foregroundStyle(.blue)
        case .audioReady:
            Image(systemName: "play.circle.fill")
                .foregroundStyle(.green)
                .font(.title3)
        case .playing:
            Image(systemName: "speaker.wave.2.fill")
                .foregroundStyle(.blue)
                .symbolEffect(.variableColor.iterative)
        case .played:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.secondary)
        }
    }

    private func formatDuration(_ seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, secs)
    }
}

/// Apple Podcasts-style download progress circle.
/// Shows a filling circular arc with percentage when progress is known,
/// or a pulsing indeterminate indicator when progress is nil.
struct DownloadProgressCircle: View {
    let progress: Double?

    @State private var isPulsing = false

    var body: some View {
        ZStack {
            // Background track
            Circle()
                .stroke(Color.blue.opacity(0.2), lineWidth: 3)

            if let progress {
                // Determinate: filling arc
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.3), value: progress)

                // Center percentage
                Text("\(Int(progress * 100))")
                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                    .foregroundStyle(.blue)
            } else {
                // Indeterminate: pulsing filled circle
                Circle()
                    .fill(Color.blue.opacity(isPulsing ? 0.35 : 0.15))
                    .padding(4)
                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isPulsing)
                    .onAppear { isPulsing = true }

                Image(systemName: "arrow.down")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.blue)
            }
        }
    }
}
