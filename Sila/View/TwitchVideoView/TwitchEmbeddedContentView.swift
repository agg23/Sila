//
//  TwitchEmbeddedContentView.swift
//  Sila
//
//  Created by Adam Gastineau on 12/23/25.
//

import SwiftUI

struct TwitchEmbeddedContentView: View {
    @State private var controlVisibility = Visibility.visible
    @State private var player = WebViewPlayer()

    let streamableVideo: StreamableVideo

    var body: some View {
        TwitchContentView(controlVisibility: self.$controlVisibility, player: self.player, streamableVideo: self.streamableVideo, isStandaloneWindow: false)
            .roundedBackground(.solid(.black))
    }
}
