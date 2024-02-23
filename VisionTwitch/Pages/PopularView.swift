//
//  BrowseView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/18/24.
//

import SwiftUI
import Twitch

struct PopularView: View {
    @State private var loader = DataLoader<[Twitch.Stream], AuthStatus>()

    var body: some View {
        StandardScrollableDataView(loader: self.$loader) { api, _ in
            let (streams, _) = try await api.getStreams(limit: 100)
            return streams
        } content: { streams in
            StreamGridView(streams: streams)
        }
    }
}

#Preview {
    TabPage(title: "Popular", systemImage: "star") {
        ScrollGridView {
            StreamGridView(streams: STREAMS_LIST_MOCK())
        }
    }
}
