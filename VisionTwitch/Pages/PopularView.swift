//
//  BrowseView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/18/24.
//

import SwiftUI
import Twitch

struct PopularView: View {
    @State private var state: DataProvider<[Twitch.Stream], Error>? = DataProvider(taskClosure: { api in
        return Task {
            let (streams, _) = try await api.getStreams(limit: 100)
            return streams
        }
    }, requiresAuth: false)

    var body: some View {
        DataView(provider: $state, content: { streams in
            ScrollGridView {
                StreamGridView(streams: streams)
            }
        }, error: { _ in
            Text("Error")
        }, requiresAuth: false)
    }
}

#Preview {
    TabPage(title: "Popular", systemImage: "star") {
        ScrollGridView {
            StreamGridView(streams: STREAMS_LIST_MOCK())
        }
    }
}
