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
    @State private var existingIds = Set<String>()

    var body: some View {
        StandardDataView(loader: self.$loader) { api, _ in
            let streams = try await api.getStreams(limit: 100)

            self.existingIds.formUnion(streams.streams.map({ $0.id }))

            return (streams.streams, streams.cursor)
        } content: { streams, _ in
            MatureStreamFilterView(streams: streams) { streams in
                if streams.isEmpty {
                    EmptyDataView(title: "No Livestreams", systemImage: Icon.popular, message: "livestreams") {
                        Task {
                            try await self.loader.refresh()
                        }
                    }
                } else {
                    RefreshableScrollGridView(loader: self.loader) {
                        StreamGridView(streams: streams, onPaginationThresholdMet: self.onPaginationThresholdMet)
                    }
                }
            }
        }
    }

    func onPaginationThresholdMet() async {
        print("Loading more")
        await self.loader.requestMore { data, apiAndUser in
            guard let originalCursor = data.1 else {
                return data
            }

            let (newData, cursor) = try await apiAndUser.0.getStreams(limit: 100, after: originalCursor)

            // Prevent duplicates from appearing, due to the list resorting while being fetched
            let newStreams = newData.filter({ !self.existingIds.contains($0.id) })
            self.existingIds.formUnion(newStreams.map({ $0.id }))

            return (data.0 + newStreams, cursor)
        }
    }
}

#Preview {
    TabPage(title: "Popular", systemImage: "star", tab: .popular) {
        ScrollGridView {
            StreamGridView(streams: STREAMS_LIST_MOCK())
        }
    }
}

#Preview {
    TabPage(title: "Popular", systemImage: "star", tab: .popular) {
        ScrollGridView {
            EmptyDataView(title: "No Livestreams", systemImage: Icon.popular, message: "any livestreams") {

            }
        }
    }
}
