//
//  ChannelGridView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/19/24.
//

import SwiftUI
import Twitch

struct ChannelGridView: View {
    #if os(tvOS)
    private static let columnSpacing: CGFloat = 24
    private static let columns: [GridItem] = Array(repeating: GridItem(.flexible(), spacing: ChannelGridView.columnSpacing, alignment: .top), count: 6)
    #elseif os(macOS)
    private static let columnSpacing: CGFloat = 16
    private static let columns: [GridItem] = [GridItem(.adaptive(minimum: 150), spacing: ChannelGridView.columnSpacing, alignment: .top)]
    #else
    private static let columnSpacing: CGFloat = 16
    private static let columns: [GridItem] = Array(repeating: GridItem(.flexible(), spacing: ChannelGridView.columnSpacing, alignment: .top), count: 6)
    #endif


    let channels: [Twitch.User]

    var body: some View {
        // TODO: Optimize sort
        let sortedChannels = self.channels.sorted(by: { a, b in
            a.displayName.localizedCompare(b.displayName) == .orderedAscending
        })

        LazyVGrid(columns: ChannelGridView.columns, spacing: ChannelGridView.columnSpacing, content: {
            ForEach(sortedChannels, id: \.id) { user in
                ChannelButtonView(channel: user)
            }
        })
    }
}

#Preview {
    ChannelGridView(channels: USER_LIST_MOCK())
}
