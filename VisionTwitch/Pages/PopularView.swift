//
//  BrowseView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/18/24.
//

import SwiftUI

struct PopularView: View {
    var body: some View {
        DataView(taskClosure: { api in
            return Task {
                let (streams, _) = try await api.getStreams(limit: 100)
                return streams
            }
        }, content: { streams in
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
