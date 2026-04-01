#if os(tvOS)
import SwiftUI
import Twitch

struct TwitchVideoView: View {
    private enum FocusTarget: Hashable {
        case playbackSurface
    }

    let controlsTimerDuration = 8.0

    @Environment(AuthController.self) private var authController
    @Environment(Router.self) private var router

    @FocusState private var focusTarget: FocusTarget?

    @Binding var controlVisibility: Visibility
    @State private var controlVisibilityTimer: Timer?

    @State private var volume: CGFloat = 0.5
    @State private var liveUpdatedStream: StreamableVideo?
    @State private var streamRefreshTask: Task<(), Never>?

    let streamRefreshTimer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    let streamableVideo: StreamableVideo

    /// Allow delaying of loading Twitch content to provide time for all other players to mute, allowing concurrent playback
    let delayLoading: Bool

    @Bindable var player: WebViewPlayer

    var body: some View {
        TwitchWebView(player: self.player, streamableVideo: self.streamableVideo, delayLoading: self.delayLoading)
            .overlay {
                if self.player.loading || self.delayLoading {
                    ProgressView()
                        .controlSize(.large)
                }
            }
            .overlay(alignment: .top) {
                self.topOverlayControls
            }
            .contentShape(Rectangle())
            .focusable(true)
            .focused(self.$focusTarget, equals: .playbackSurface)
            .onTapGesture {
                self.togglePlayback()
            }
            .onExitCommand {
                self.router.dismissPlayback()
            }
            .onPlayPauseCommand {
                self.togglePlayback()
            }
            .onAppear {
                self.focusTarget = .playbackSurface
            }
            .onReceive(self.streamRefreshTimer) { _ in
                guard let channelId = self.player.channelId else {
                    return
                }

                self.fetchStreamData(channelId: channelId)
            }
            .task {
                let channel: String
                let channelId: String
                switch self.streamableVideo {
                case .stream(let stream):
                    channel = stream.userName
                    channelId = stream.userID
                case .video(let video):
                    channel = video.userName
                    channelId = video.userID
                }

                self.player.channelId = channelId
                self.player.channel = channel

                self.fetchStreamData(channelId: channelId)
            }
            .onChange(of: self.player.status) { oldValue, newValue in
                if newValue == .idle {
                    self.forceVisibility()
                } else if oldValue == .idle && newValue != .idle {
                    self.resetTimer()
                }

                self.focusTarget = .playbackSurface
            }
    }

    @ViewBuilder
    private var topOverlayControls: some View {
        PlayerOverlayControlsView(player: self.player, volume: self.$volume, streamableVideo: self.liveUpdatedStream ?? self.streamableVideo, isVisible: self.controlVisibility == .visible, onInteraction: self.onControlInteraction) { isActive in
            if isActive {
                print("Controls are active")
                self.forceVisibility()
            } else {
                self.resetTimer()
            }
        }
    }

    func togglePlayback() {
        if self.player.isPlaying {
            self.player.pause()
        } else {
            self.player.play()
        }

        self.focusTarget = .playbackSurface
    }

    func onControlInteraction() {
        withAnimation {
            self.controlVisibility = .visible
        }
        self.resetTimer()
    }

    func resetTimer() {
        print("Resetting timer")
        self.controlVisibilityTimer?.invalidate()
        self.controlVisibilityTimer = Timer.scheduledTimer(withTimeInterval: self.controlsTimerDuration, repeats: false, block: { _ in
            guard self.player.status != .idle else {
                self.forceVisibility()
                return
            }

            withAnimation {
                self.controlVisibility = .hidden
            }
        })
    }

    func clearTimer() {
        self.controlVisibilityTimer?.invalidate()
        self.controlVisibilityTimer = nil
    }

    func forceVisibility() {
        self.clearTimer()
        withAnimation {
            self.controlVisibility = .visible
        }
    }

    private func fetchStreamData(channelId: String) {
        self.streamRefreshTask?.cancel()

        self.streamRefreshTask = Task {
            guard let api = self.authController.status.api() else {
                return
            }

            do {
                let streams = try await api.helix(endpoint: .getStreams(userIDs: [channelId]))
                self.liveUpdatedStream = streams.0.first.map { stream in .stream(stream) }
            } catch {
                print("Error fetching stream data: \(error)")
            }

            self.streamRefreshTask = nil
        }
    }
}
#endif
