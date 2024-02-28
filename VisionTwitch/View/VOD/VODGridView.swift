//
//  VODGridView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/27/24.
//

import SwiftUI
import Twitch

struct VODGridView: View {
    let videos: [Video]

    var body: some View {
        LazyVGrid(columns: [
            GridItem(),
            GridItem(),
            GridItem(),
            GridItem()
        ], content: {
            ForEach(self.videos, id: \.id) { video in
                VODButtonView(video: video)
            }
        })
    }
}

#Preview {
    VODGridView(videos: VIDEO_LIST_MOCK())
}
