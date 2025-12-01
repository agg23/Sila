//
//  StreamGridView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/18/24.
//

import SwiftUI
import Twitch

struct StreamGridView: View {
    private static let columnSpacing: CGFloat = 16
    private static let columns: [GridItem] = Array(
        repeating: GridItem(.flexible(), spacing: StreamGridView.columnSpacing, alignment: .top),
        count: 4
    )

    let streams: [Twitch.Stream]

    let refreshToken: RefreshToken
    let onPaginationThresholdMet: (() async -> Void)?

    internal init(streams: [Twitch.Stream], refreshToken: RefreshToken, onPaginationThresholdMet: (() async -> Void)? = nil) {
        self.streams = streams
        self.refreshToken = refreshToken
        self.onPaginationThresholdMet = onPaginationThresholdMet
    }

    var body: some View {
        LazyVGrid(columns: StreamGridView.columns, spacing: StreamGridView.columnSpacing) {
            ForEach(self.streams) { stream in
                StreamButtonView(stream: stream, refreshToken: refreshToken)
            }

            Color.clear
                .frame(height: 1)
                .onAppear {
                    guard let onPaginationThresholdMet = self.onPaginationThresholdMet else {
                        return
                    }

                    Task {
                        await onPaginationThresholdMet()
                    }
                }
        }
    }
}

#Preview {
    PreviewNavStack {
        StreamGridView(streams: STREAMS_LIST_MOCK(), refreshToken: UUID())
    }
}
