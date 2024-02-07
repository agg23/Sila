//
//  TwitchVideoView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/2/24.
//

import SwiftUI
import WebKit
import Swifter

struct TwitchVideoView: View {
    @State var reload = false
    @State var status: PlaybackStatus = .idle

    var body: some View {
        WebView(reload: $reload, status: $status)
            .aspectRatio(16/9, contentMode: .fit)
        HStack {
            Button(action: {
                self.reload = true
            }, label: {
                Text("Reload")
            })
            Button {
                self.status = .playing
            } label: {
                Text("Play")
            }
            Button {
                self.status = .idle
            } label: {
                Text("Stop")
            }
        }
    }
}

#Preview {
    TwitchVideoView()
}
