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

    @State var showControls = false
    @State var showControlsTimer: Timer?

    var body: some View {
        ZStack {
            TwitchWebView(player: self.player)
                .aspectRatio(16/9, contentMode: .fit)
                .onTapGesture {
                    self.showControls = true

                    self.showControlsTimer?.invalidate()
                    self.showControlsTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: false, block: { _ in
                        self.showControls = false
                    })
                }
            if self.showControls {
                PlayerControlsView(player: player)
            }
        }
    }
}

#Preview {
    TwitchVideoView()
}
