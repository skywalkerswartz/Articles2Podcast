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

            if article.state.isProcessing {
                progressIndicator
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var stateIcon: some View {
        switch article.state {
        case .pendingExtraction:
            Image(systemName: "clock")
                .foregroundStyle(.secondary)
        case .extracting, .generatingAudio:
            ProgressView()
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

    @ViewBuilder
    private var progressIndicator: some View {
        if article.state == .generatingAudio {
            let progress = article.generationProgress
            if progress > 0 {
                CircularProgressView(progress: progress)
                    .frame(width: 28, height: 28)
            }
        }
    }

    private func formatDuration(_ seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, secs)
    }
}

struct CircularProgressView: View {
    let progress: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 3)
                .opacity(0.1)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .foregroundStyle(.blue)
                .rotationEffect(.degrees(-90))
        }
    }
}
