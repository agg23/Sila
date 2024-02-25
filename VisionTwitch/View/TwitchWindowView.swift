//
//  TwitchWindowView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/18/24.
//

import SwiftUI
import Twitch

struct TwitchWindowView: View {
    @Environment(\.dismissWindow) private var dismissWindow

    let stream: Twitch.Stream

    var body: some View {
        TwitchVideoView(stream: self.stream)
            // Set aspect ratio and enforce uniform resizing
            .windowGeometryPreferences(minimumSize: CGSize(width: 160.0, height: 90.0), resizingRestrictions: .uniform)
            .persistentSystemOverlays(.hidden)
            .onAppear {
                NotificationCenter.default.post(name: .twitchMuteAll, object: nil, userInfo: nil)
            }
            .onReceive(NotificationCenter.default.publisher(for: .twitchLogOut), perform: { _ in
                dismissWindow()
            })
    }
}

#Preview {
    TwitchWindowView(stream: STREAM_MOCK())
}
