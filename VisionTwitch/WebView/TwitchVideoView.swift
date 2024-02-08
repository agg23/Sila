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
        ZStack {
            WebView(player: self.player)
                .aspectRatio(16/9, contentMode: .fit)
//            PlayerControlsView(player: player)
        }
    }
}

#Preview {
    TwitchVideoView()
}
