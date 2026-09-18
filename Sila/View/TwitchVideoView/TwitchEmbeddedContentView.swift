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
            #if os(macOS)
            // When macOS is given a black background, it pops in and out of the title area
            .background(.black)
            #else
            .roundedBackground(.solid(.black))
            #endif
    }
}
