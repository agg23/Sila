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

    @State private var showControls = false
    @State private var showControlsTimer: Timer?
    @State private var showChat = false

    @State private var preventClose = false

    @State private var player = WebViewPlayer()

    let streamableVideo: StreamableVideo

    var body: some View {
        let forceControlsDisplay = self.player.status == .idle
        let controlOpacity = self.showControls || forceControlsDisplay ? 1.0 : 0.0

        ZStack {
            TwitchWebView(player: self.player, streamableVideo: self.streamableVideo)
                .onTapGesture {
                    self.showControls = true
                    
                    resetTimer()
                }
        }
        .pane(isPresented: self.$showChat) {
            // TODO: Handle VoDs
            if case .stream(let stream) = self.streamableVideo {
                ChatPaneView(channel: stream.userName)
            }
        }
        .ornament(attachmentAnchor: .scene(.bottom), contentAlignment: .top) {
            VStack {
                // Add spacing between main window and PlayerControlsView to allow for the window resizer
                Color.clear.frame(height: 32)
                PlayerControlsView(player: self.player, streamableVideo: self.streamableVideo, showChat: self.$showChat) {
                    resetTimer()
                } activeChanged: { isActive in
                    if isActive {
                        print("Controls are active")
                        self.showControlsTimer?.invalidate()
                        self.showControlsTimer = nil
                    } else {
                        self.resetTimer()
                    }
                }
                    .glassBackgroundEffect()
                    .opacity(controlOpacity)
                    .animation(.easeInOut(duration: 0.5), value: controlOpacity)
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
    }
    
    func resetTimer() {
        print("Resetting timer")
        self.showControlsTimer?.invalidate()
        self.showControlsTimer = Timer.scheduledTimer(withTimeInterval: self.controlsTimerDuration, repeats: false, block: { _ in
            self.showControls = false
        })
    }
}

#Preview {
    TwitchVideoView(streamableVideo: .stream(STREAM_MOCK()))
}
