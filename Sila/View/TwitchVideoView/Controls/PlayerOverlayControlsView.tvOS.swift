#if os(tvOS)
import SwiftUI

struct PlayerOverlayControlsView: View {
    @Bindable var player: WebViewPlayer
    @Binding var volume: CGFloat

    let streamableVideo: StreamableVideo
    let isVisible: Bool

    let onInteraction: () -> Void
    let activeChanged: (Bool) -> Void

    var body: some View {
        TVPlayerInfoOverlayView(streamableVideo: self.streamableVideo, isPlaying: self.player.isPlaying, isVisible: self.isVisible)
    }
}

private struct TVPlayerInfoOverlayView: View {
    let streamableVideo: StreamableVideo
    let isPlaying: Bool
    let isVisible: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            self.header
            Text(self.isPlaying ? "Playing" : "Paused")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 44)
        .padding(.top, 28)
        .padding(.bottom, 56)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            LinearGradient(colors: [.black.opacity(self.isVisible ? 0.9 : 0.72), .black.opacity(0.45), .clear], startPoint: .top, endPoint: .bottom)
        }
        .opacity(self.isVisible ? 1 : 0)
        .allowsHitTesting(false)
        .animation(.easeInOut(duration: 0.2), value: self.isVisible)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(self.displayTitle)
                .font(.title2.weight(.semibold))
                .lineLimit(1)

            Text(self.displaySubtitle)
                .font(.headline)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }

    private var displayTitle: String {
        let title = self.streamableVideo.title.trimmingCharacters(in: .whitespacesAndNewlines)
        return title.isEmpty ? self.streamableVideo.userName : title
    }

    private var displaySubtitle: String {
        switch self.streamableVideo {
        case .stream(let stream):
            let category = stream.gameName.trimmingCharacters(in: .whitespacesAndNewlines)
            return category.isEmpty ? stream.userName : "\(stream.userName) • \(category)"
        case .video(let video):
            return video.userName
        }
    }
}
#endif
