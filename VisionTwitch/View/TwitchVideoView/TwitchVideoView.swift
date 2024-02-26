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
    @State private var showControls = false
    @State private var showControlsTimer: Timer?

    @State private var preventClose = false

    let stream: Twitch.Stream

    let player = WebViewPlayer()

    var body: some View {
        let forceControlsDisplay = self.player.status == .idle
        let controlOpacity = self.showControls || forceControlsDisplay ? 1.0 : 0.0

        ZStack {
            TwitchWebView(player: self.player, channel: self.stream.userName)
                .onTapGesture {
                    self.showControls = true
                    
                    resetTimer()
                }
        }
        .ornament(attachmentAnchor: .scene(.bottom), contentAlignment: .top) {
                PlayerControlsView(player: player, stream: self.stream, onInteraction: {
                    resetTimer()
                }, activeChanged: { isActive in
                    if isActive {
                        self.showControlsTimer?.invalidate()
                        self.showControlsTimer = nil
                    } else {
                        self.resetTimer()
                    }
                })
                    .glassBackgroundEffect()
                    .opacity(controlOpacity)
                    .animation(.easeInOut(duration: 0.5), value: controlOpacity)
            }
    }
    
    func resetTimer() {
        self.showControlsTimer?.invalidate()
        self.showControlsTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: false, block: { _ in
            self.showControls = false
        })
    }
}

#Preview {
    TwitchVideoView(stream: STREAM_MOCK())
}
