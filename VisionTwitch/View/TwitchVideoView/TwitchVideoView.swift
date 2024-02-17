//
//  TwitchVideoView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/2/24.
//

import SwiftUI
import WebKit

struct TwitchVideoView: View {
    let channel: String

    let player = WebViewPlayer()
    
    @State var showControls = false
    @State var showControlsTimer: Timer?
    
    var body: some View {
        let forceControlsDisplay = self.player.status == .idle
        let controlOpacity = self.showControls || forceControlsDisplay ? 1.0 : 0.0

        ZStack {
            TwitchWebView(player: self.player, channel: self.channel)
                .onTapGesture {
                    self.showControls = true
                    
                    resetTimer()
                }
        }
            .ornament(attachmentAnchor: .scene(.bottom)) {
                PlayerControlsView(player: player, onButtonPress: {
                    resetTimer()
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
    TwitchVideoView(channel: "BarbarousKing")
}
