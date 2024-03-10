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

    let onPaginationThresholdMet: (() async -> Void)?

    internal init(videos: [Video], onPaginationThresholdMet: (() async -> Void)? = nil) {
        self.videos = videos
        self.onPaginationThresholdMet = onPaginationThresholdMet
    }

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
            
            Color.clear.task {
                await self.onPaginationThresholdMet?()
            }
        })
    }
}

#Preview {
    VODGridView(videos: VIDEO_LIST_MOCK())
}
