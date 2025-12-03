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
    static let ornamentSpacing = 8.0

    @State private var loading = true

    @Binding var controlVisibility: Visibility
    @State private var controlVisibilityTimer: Timer?
    @State private var chatVisible = false

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
            // .center is used so the ornament isn't cut off at the edge (or a little past the edge) of the window
            // This would break the appearance animation
            .ornament(attachmentAnchor: .scene(.trailing), contentAlignment: .center) {
                // Calibrated for a 400 width at default window size
                let chatWidth = max(geometry.size.width * 0.3125, 400)
                let contentWidth = TwitchVideoView.ornamentSpacing + chatWidth

                HStack {
                    // Gap covering the left side of the ornament (over the video), plus some extra for the ornament spacing
                    Color.clear
                        .frame(width: contentWidth + 40)

                    // Ornament automatically applies an animation when resizing the view. Thus we always display a clear view and just animate in chat
                    Group {
                        if self.chatVisible {
                            // TODO: Handle VoDs
                            if case .stream(let stream) = self.streamableVideo {
                                ChatContentView(channelName: stream.userLogin, userId: stream.userID, title: stream.userName, isWindow: false) {
                                    withChatAnimation {
                                        self.chatVisible = false
                                    }
                                }
                            }
                        } else {
                            Color.clear
                        }
                    }
                    .frame(width: chatWidth, height: geometry.size.height)
                    .transition(.chatTranstion(contentWidth: contentWidth))
                }
            }
            .ornament(visibility: self.controlVisibility, attachmentAnchor: .scene(.bottom), contentAlignment: .top) {
                VStack {
                    // Add spacing between main window and PlayerControlsView to allow for the window resizer
                    Color.clear.frame(height: TwitchVideoView.ornamentSpacing)
                    PlayerOranamentControlsView(player: self.player, streamableVideo: self.streamableVideo, chatVisible: self.$chatVisible) {
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
                    channelId = stream.userID
                case .video(let video):
                    channel = video.userName
                    channelId = video.userID
                }

                self.player.channelId = channelId
                self.player.channel = channel

                await EmoteController.shared.fetchUserEmotes(for: channelId)
            }
            .onReceive(WindowController.shared.popoutChatSubject, perform: { popoutUserId in
                if popoutUserId == self.player.channelId {
                    withAnimation {
                        self.chatVisible = true
                    }
                }
            })
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
