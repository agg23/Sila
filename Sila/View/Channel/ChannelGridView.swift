//
//  ChannelGridView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/19/24.
//

import SwiftUI
import Twitch

struct ChannelGridView: View {
    let channels: [Twitch.User]

    var body: some View {
        // TODO: Optimize sort
        let sortedChannels = self.channels.sorted(by: { a, b in
            a.displayName.localizedCompare(b.displayName) == .orderedAscending
        })

        LazyVGrid(columns: [
            GridItem(),
            GridItem(),
            GridItem(),
            GridItem(),
            GridItem(),
            GridItem()
        ], content: {
            ForEach(sortedChannels, id: \.id) { user in
                ChannelButtonView(channel: user)
            }
        })
    }
}

#Preview {
    ChannelGridView(channels: USER_LIST_MOCK())
}
