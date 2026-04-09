//
//  StreamGridView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/18/24.
//

import SwiftUI
import Twitch

struct StreamGridView: View {
    #if os(tvOS)
    private static let columnSpacing: CGFloat = 64
    private static let columns: [GridItem] = Array(
        repeating: GridItem(.flexible(), spacing: StreamGridView.columnSpacing, alignment: .top),
        count: 4
    )
    #else
    private static let columnSpacing: CGFloat = 16
    private static let columns: [GridItem] = {
        #if os(macOS)
        [GridItem(.adaptive(minimum: 300), spacing: StreamGridView.columnSpacing, alignment: .top)]
        #else
        Array(
            repeating: GridItem(.flexible(), spacing: StreamGridView.columnSpacing, alignment: .top),
            count: 4
        )
        #endif
    }()
    #endif

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
                    // If we don't have at least 12 streams on screen, we can't possibly have more data to fetch
                    // This is just triggering on initial render. Don't do anything
                    guard self.streams.count > 12 else {
                        return
                    }

                    guard let onPaginationThresholdMet = self.onPaginationThresholdMet else {
                        return
                    }

                    Task {
                        await onPaginationThresholdMet()
                    }
                }
        }
        #if os(tvOS)
        .scrollClipDisabled()
        #endif
    }
}

#Preview {
    PreviewNavStack {
        StreamGridView(streams: STREAMS_LIST_MOCK(), refreshToken: UUID())
    }
}
