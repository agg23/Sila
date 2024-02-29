//
//  BrowseView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/18/24.
//

import SwiftUI
import Twitch

struct PopularView: View {
    @State private var loader = StandardDataLoader<([Twitch.Stream], String?)>()

    var body: some View {
        StandardScrollableDataView(loader: self.$loader) { api, _ in
            return try await api.getStreams(limit: 100)
        } onPaginationThresholdMet: {
            print("Loading more")
            await self.loader.requestMore { data, apiAndUser in
                let (newData, cursor) = try await apiAndUser.0.getStreams(limit: 100, after: data.1)

                return (data.0 + newData, cursor)
            }
        } content: { streams, _ in
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
