#if os(tvOS)
import SwiftUI

struct PlayerOverlayControlsView: View {
    @Environment(Router.self) private var router

    @Bindable var player: WebViewPlayer
    @Binding var volume: CGFloat

    let streamableVideo: StreamableVideo

    let onInteraction: () -> Void
    let activeChanged: (Bool) -> Void

    private enum Control: Hashable {
        case playPause, quality, reload, done
    }

    @FocusState private var focusedControl: Control?

    @State private var isQualityPickerPresented = false

    var body: some View {
        VStack(spacing: 0) {
            TVPlayerInfoOverlayView(streamableVideo: self.streamableVideo, isPlaying: self.player.isPlaying, isVisible: true)

            Spacer()

            self.transportBar
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onChange(of: self.focusedControl) { _, _ in
            self.activeChanged(self.isActive)
        }
        .onChange(of: self.isQualityPickerPresented) { _, _ in
            self.activeChanged(self.isActive)
        }
    }

    private var isActive: Bool {
        self.focusedControl != nil || self.isQualityPickerPresented
    }

    private var currentQualityName: String {
        self.player.availableQualities.first(where: { $0.quality == self.player.quality })?.name ?? "Quality"
    }

    private var transportBar: some View {
        HStack(spacing: 24) {
            PlayerOverlayButtonView(label: self.player.isPlaying ? "Pause" : "Play", icon: self.player.isPlaying ? Icon.pause : Icon.play) {
                if self.player.isPlaying {
                    self.player.pause()
                } else {
                    self.player.play()
                }
                self.onInteraction()
            }
            .focused(self.$focusedControl, equals: .playPause)

            if !self.player.isVideo && self.player.availableQualities.count > 1 {
                PlayerOverlayButtonView(label: self.currentQualityName, icon: Icon.quality) {
                    self.isQualityPickerPresented = true
                }
                .focused(self.$focusedControl, equals: .quality)
                .confirmationDialog("Quality", isPresented: self.$isQualityPickerPresented, titleVisibility: .visible) {
                    // Qualties are saved in reverse order
                    ForEach(self.player.availableQualities.reversed(), id: \.quality) { quality in
                        Button(quality.quality == self.player.quality ? "\(quality.name) ✓" : quality.name) {
                            self.player.setQuality(quality.quality)
                            self.onInteraction()
                        }
                    }
                }
            }

            PlayerOverlayButtonView(label: "Reload", icon: Icon.refresh) {
                self.player.reload()
                self.onInteraction()
            }
            .focused(self.$focusedControl, equals: .reload)

            PlayerOverlayButtonView(label: "Done", icon: Icon.back) {
                self.router.dismissPlayback()
            }
            .focused(self.$focusedControl, equals: .done)
        }
        .focusSection()
        .padding(.horizontal, 44)
        .padding(.bottom, 48)
        .padding(.top, 28)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            LinearGradient(colors: [.clear, .black.opacity(0.55), .black.opacity(0.85)], startPoint: .top, endPoint: .bottom)
        }
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
