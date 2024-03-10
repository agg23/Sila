//
//  TwitchVideoView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/2/24.
//

import SwiftUI
import Twitch
import WebKit

struct TwitchVideoView: View {
    let controlsTimerDuration = 5.0
    let ornamentSpacing = 32.0

    @State private var loading = true

    @State private var controlVisibility = Visibility.hidden
    @State private var controlVisibilityTimer: Timer?
    @State private var chatVisibility = Visibility.hidden

    @State private var preventClose = false

    let streamableVideo: StreamableVideo

    /// Allow delaying of loading Twitch content to provide time for all other players to mute, allowing concurrent playback
    let delayLoading: Bool

    @Binding var player: WebViewPlayer

    var body: some View {
        GeometryReader { geometry in
            self.content(geometry)
        }
    }

    @ViewBuilder
    func content(_ geometry: GeometryProxy) -> some View {
        TwitchWebView(player: self.player, streamableVideo: self.streamableVideo, loading: self.$loading, delayLoading: self.delayLoading)
            .overlay {
                if self.loading || self.delayLoading {
                    ProgressView()
                        .controlSize(.large)
                }
            }
            .onTapGesture {
                if self.controlVisibility == .visible {
                    clearTimer()
                } else {
                    resetTimer()
                }

                withAnimation {
                    self.controlVisibility = self.controlVisibility != .visible ? .visible : .hidden
                }
            }
            .ornament(visibility: self.chatVisibility, attachmentAnchor: .scene(.trailing), contentAlignment: .leading) {
                // TODO: Handle VoDs
                if case .stream(let stream) = self.streamableVideo {
                    HStack {
                        Color.clear.frame(width: self.ornamentSpacing)
                        ChatPaneView(channel: stream.userLogin, title: stream.userName) {
                            withAnimation {
                                self.chatVisibility = .hidden
                            }
                        }
                            .frame(width: 400, height: geometry.size.height)
                            .glassBackgroundEffect(tint: .black.opacity(0.5))
                    }
                }
            }
            .ornament(visibility: self.controlVisibility, attachmentAnchor: .scene(.bottom), contentAlignment: .top) {
                VStack {
                    // Add spacing between main window and PlayerControlsView to allow for the window resizer
                    Color.clear.frame(height: self.ornamentSpacing)
                    PlayerControlsView(player: self.player, streamableVideo: self.streamableVideo, chatVisibility: self.$chatVisibility) {
                        withAnimation {
                            self.controlVisibility = .visible
                        }
                        self.resetTimer()
                    } activeChanged: { isActive in
                        if isActive {
                            print("Controls are active")
                            withAnimation {
                                self.controlVisibility = .visible
                            }
                            self.clearTimer()
                        } else {
                            self.resetTimer()
                        }
                    }
                        .glassBackgroundEffect()
                }
            }
            .onAppear {
                let channel: String
                let channelId: String
                switch self.streamableVideo {
                case .stream(let stream):
                    channel = stream.userName
                    channelId = stream.userId
                case .video(let video):
                    channel = video.userName
                    channelId = video.userId
                }

                self.player.channelId = channelId
                self.player.channel = channel
            }
            .onChange(of: self.player.status) { oldValue, newValue in
                if newValue == .idle {
                    withAnimation {
                        self.controlVisibility = .visible
                    }
                } else if oldValue == .idle && newValue != .idle {
                    self.resetTimer()
                }
            }
    }

    func resetTimer() {
        print("Resetting timer")
        self.controlVisibilityTimer?.invalidate()
        self.controlVisibilityTimer = Timer.scheduledTimer(withTimeInterval: self.controlsTimerDuration, repeats: false, block: { _ in
            withAnimation {
                self.controlVisibility = .hidden
            }
        })
    }

    func clearTimer() {
        self.controlVisibilityTimer?.invalidate()
        self.controlVisibilityTimer = nil
    }
}

#Preview {
    @State var player = WebViewPlayer()

    return TwitchVideoView(streamableVideo: .stream(STREAM_MOCK()), delayLoading: false, player: $player)
}
