import SwiftUI

struct PlaybackSpeedPicker: View {
    @Binding var rate: Float

    private let speeds: [Float] = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(speeds, id: \.self) { speed in
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        rate = speed
                    }
                } label: {
                    Text(formatSpeed(speed))
                        .font(.caption)
                        .fontWeight(rate == speed ? .bold : .regular)
                        .foregroundStyle(rate == speed ? .white : .primary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background {
                            if rate == speed {
                                Capsule()
                                    .fill(.blue)
                            }
                        }
                }
            }
        }
        .padding(4)
        .background {
            Capsule()
                .fill(.quaternary)
        }
    }

    private func formatSpeed(_ speed: Float) -> String {
        if speed == Float(Int(speed)) {
            return "\(Int(speed))x"
        } else {
            return String(format: "%.2gx", speed)
        }
    }
}

#Preview {
    @Previewable @State var rate: Float = 1.0
    PlaybackSpeedPicker(rate: $rate)
}
