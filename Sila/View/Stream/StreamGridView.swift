//
//  StreamGridView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/18/24.
//

import SwiftUI
import Twitch

struct StreamGridView: View {
    let streams: [Twitch.Stream]

    let onPaginationThresholdMet: (() async -> Void)?

    internal init(streams: [Twitch.Stream], onPaginationThresholdMet: (() async -> Void)? = nil) {
        self.streams = streams
        self.onPaginationThresholdMet = onPaginationThresholdMet
    }

    var body: some View {
        LazyVGrid(columns: [
            GridItem(spacing: 16),
            GridItem(spacing: 16),
            GridItem(spacing: 16),
            GridItem(spacing: 16)
        ], spacing: 16) {
            ForEach(self.streams) { stream in
                StreamButtonView(stream: stream)
            }

            Color.clear.task {
                await self.onPaginationThresholdMet?()
            }
        }
    }
}

#Preview {
    NavStack {
        StreamGridView(streams: STREAMS_LIST_MOCK())
    }
    .environment(StreamTimer())
}
