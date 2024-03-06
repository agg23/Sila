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
    let controlsTimerDuration = 3.0

    @State private var controlVisibility = Visibility.hidden
    @State private var controlVisibilityTimer: Timer?
    @State private var showChat = false

    @State private var preventClose = false

    @State private var player = WebViewPlayer()

    let streamableVideo: StreamableVideo

    var body: some View {
        let forceControlsDisplay = self.player.status == .idle

        ZStack {
            TwitchWebView(player: self.player, streamableVideo: self.streamableVideo)
                .onTapGesture {
                    withAnimation {
                        self.controlVisibility = .visible
                    }

                    resetTimer()
                }
        }
        .pane(isPresented: self.$showChat) {
            // TODO: Handle VoDs
            if case .stream(let stream) = self.streamableVideo {
                ChatPaneView(channel: stream.userName)
            }
        }
        .ornament(visibility: self.controlVisibility, attachmentAnchor: .scene(.bottom), contentAlignment: .top) {
            VStack {
                // Add spacing between main window and PlayerControlsView to allow for the window resizer
                Color.clear.frame(height: 32)
                PlayerControlsView(player: self.player, streamableVideo: self.streamableVideo, showChat: self.$showChat) {
                    resetTimer()
                } activeChanged: { isActive in
                    if isActive {
                        print("Controls are active")
                        self.controlVisibilityTimer?.invalidate()
                        self.controlVisibilityTimer = nil
                    } else {
                        self.resetTimer()
                    }
                }
                    .glassBackgroundEffect()
            }
        }
        .persistentSystemOverlays(self.controlVisibility)
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
}

#Preview {
    TwitchVideoView(streamableVideo: .stream(STREAM_MOCK()))
}
