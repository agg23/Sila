//
//  TwitchVideoView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/2/24.
//

import SwiftUI
import Twitch
import WebKit
import VisionPane

struct TwitchVideoView: View {
    let controlsTimerDuration = 5.0

    @State private var loading = true

    @State private var controlVisibility = Visibility.hidden
    @State private var controlVisibilityTimer: Timer?
    @State private var showChat = false

    @State private var preventClose = false

    @State private var player = WebViewPlayer()

    let streamableVideo: StreamableVideo

    var body: some View {
        ZStack {
            TwitchWebView(player: self.player, streamableVideo: self.streamableVideo, loading: self.$loading)
                .overlay {
                    if self.loading {
                        ProgressView()
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
        }
        .pane(isPresented: self.$showChat) {
            // TODO: Handle VoDs
            if case .stream(let stream) = self.streamableVideo {
                ChatPaneView(channel: stream.userName)
                    .glassBackgroundEffect(tint: .black.opacity(0.5))
            }
        }
        .ornament(visibility: self.controlVisibility, attachmentAnchor: .scene(.bottom), contentAlignment: .top) {
            VStack {
                // Add spacing between main window and PlayerControlsView to allow for the window resizer
                Color.clear.frame(height: 32)
                PlayerControlsView(player: self.player, streamableVideo: self.streamableVideo, showChat: self.$showChat) {
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
    TwitchVideoView(streamableVideo: .stream(STREAM_MOCK()))
}
