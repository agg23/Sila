//
//  TwitchVideoView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/2/24.
//

import SwiftUI
import WebKit

struct TwitchVideoView: View {
    @ObservedObject var player = WebViewPlayer()

    var body: some View {
        WebView(player: self.player)
            .aspectRatio(16/9, contentMode: .fit)
        HStack {
//            Button(action: {
//                self.reload = true
//            }, label: {
//                Text("Reload")
//            })
            Button {
//                self.status = .playing
                self.player.play()
            } label: {
                Text("Play")
            }
            Button {
//                self.status = .idle
//                self.player.pause()
                self.player.pause()
            } label: {
                Text("Stop")
            }
            Button {
                self.player.toggleMute()
            } label: {
                Text("Toggle mute")
            }
        }
    }
}

#Preview {
    TwitchVideoView()
}
