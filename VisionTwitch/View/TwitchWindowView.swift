//
//  TwitchWindowView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/18/24.
//

import SwiftUI

struct TwitchWindowView: View {
    @Environment(\.dismissWindow) private var dismissWindow

    let channel: String

    var body: some View {
        TwitchVideoView(channel: self.channel)
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
    TwitchWindowView(channel: "BarbarousKing")
}
