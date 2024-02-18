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

    var body: some View {
        LazyVGrid(columns: [
            GridItem(),
            GridItem(),
            GridItem(),
            GridItem()
        ], content: {
            ForEach(self.streams, id: \.id) { stream in
                StreamButtonView(stream: stream)
            }
        })
    }
}

#Preview {
    StreamGridView(streams: STREAMS_LIST_MOCK())
}
