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
    let controlsTimerDuration = 3.0
    let ornamentSpacing = 8.0

    @State private var loading = true

    @Binding var controlVisibility: Visibility
    @State private var controlVisibilityTimer: Timer?
    @State private var chatVisibility = Visibility.hidden

    @State private var preventClose = false

    // Maintain a local volume value, which we update based on user input and the client
    // This must be located here, as locating in the overlay wipes the state
    @State private var volume: CGFloat = 0.5

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
            .overlay(alignment: .topTrailing) {
                if self.controlVisibility == .visible {
                    PlayerOverlayControlsView(player: self.$player, volume: self.$volume, onInteraction: self.onControlInteraction) { isActive in
                        if isActive {
                            print("Controls are active")
                            self.forceVisibility()
                        } else {
                            self.resetTimer()
                        }
                    }
                    .padding([.horizontal, .top], 40)
                }
            }
            .onTapGesture {
                self.toggleVisibility()
            }
            .ornament(visibility: self.chatVisibility, attachmentAnchor: .scene(.trailing), contentAlignment: .leading) {
                // Make sure we don't start loading chat while offscreen
                if self.chatVisibility != .hidden {
                    // TODO: Handle VoDs
                    if case .stream(let stream) = self.streamableVideo {
                        HStack {
                            Color.clear.frame(width: self.ornamentSpacing)
                            ChatPaneView(channel: stream.userLogin, userId: stream.userId, title: stream.userName) {
                                withAnimation {
                                    self.chatVisibility = .hidden
                                }
                            }
                            .frame(width: 400, height: geometry.size.height)
                            .glassBackgroundEffect(tint: .black.opacity(0.5))
                        }
                    }
                }
            }
            .ornament(visibility: self.controlVisibility, attachmentAnchor: .scene(.bottom), contentAlignment: .top) {
                VStack {
                    // Add spacing between main window and PlayerControlsView to allow for the window resizer
                    Color.clear.frame(height: self.ornamentSpacing)
                    PlayerControlsView(player: self.player, streamableVideo: self.streamableVideo, chatVisibility: self.$chatVisibility) {
                        self.onControlInteraction()
                    } activeChanged: { isActive in
                        if isActive {
                            print("Controls are active")
                            self.forceVisibility()
                        } else {
                            self.resetTimer()
                        }
                    }
                    .glassBackgroundEffect()
                }
            }
            .task {
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

                await EmoteController.shared.fetchUserEmotes(for: channelId)
            }
            .onChange(of: self.player.status) { oldValue, newValue in
                if newValue == .idle {
                    self.forceVisibility()
                } else if oldValue == .idle && newValue != .idle {
                    self.resetTimer()
                }
            }
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

    func toggleVisibility() {
        guard self.player.status != .idle else {
            self.forceVisibility()
            return
        }

        if self.controlVisibility == .visible {
            self.clearTimer()
        } else {
            self.resetTimer()
        }

        withAnimation {
            self.controlVisibility = self.controlVisibility != .visible ? .visible : .hidden
        }
    }

    func forceVisibility() {
        self.clearTimer()
        withAnimation {
            self.controlVisibility = .visible
        }
    }
}

#Preview {
    @State var player = WebViewPlayer()

    return TwitchVideoView(controlVisibility: .constant(.hidden), streamableVideo: .stream(STREAM_MOCK()), delayLoading: false, player: $player)
}
