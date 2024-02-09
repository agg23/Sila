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
        let playerOpacity = self.showControls ? 1.0 : 0.0

        ZStack {
            TwitchWebView(player: self.player, channel: self.channel)
                .onTapGesture {
                    self.showControls = true
                    
                    resetTimer()
                }
            PlayerControlsView(player: player, onButtonPress: {
                resetTimer()
            })
                .opacity(playerOpacity)
                .animation(.easeInOut(duration: 0.5), value: playerOpacity)
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
