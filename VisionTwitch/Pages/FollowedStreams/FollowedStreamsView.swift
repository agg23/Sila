//
//  FollowedStreamsView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/17/24.
//

import SwiftUI
import Twitch

struct FollowedStreamsView: View {
    var body: some View {
        DataView(taskClosure: { api in
            return Task {
                let (streams, _) = try await api.getFollowedStreams(limit: nil, after: nil)
                return streams
            }
        }, content: { streams in
            self.success(streams)
        }, error: { _ in
            Text("Error")
        })
    }

    @ViewBuilder
    func success(_ streams: [Twitch.Stream]) -> some View {
        LazyHStack(content: {
            ForEach(streams, id: \.id) { item in
                Button {
                    print("Clicked")
                } label: {
                    VStack {
                        AsyncImage(url: buildImageUrl(using: item))
                        Text(item.title)
                        Text(item.userName)
                        Text("Playing: \(item.gameName)")
                    }
                }

            }
        })
    }

    func buildImageUrl(using stream: Twitch.Stream) -> URL? {
        let url = stream.thumbnailURL.replacingOccurrences(of: "{width}", with: "960").replacingOccurrences(of: "{height}", with: "540")

        return URL(string: url)
    }
}

#Preview {
    FollowedStreamsView()
}
