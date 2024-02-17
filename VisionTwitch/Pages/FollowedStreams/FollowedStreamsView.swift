//
//  FollowedStreamsView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/17/24.
//

import SwiftUI
import Twitch

struct FollowedStreamsView: View {
    @State var data = DataProvider { api in
        return Task {
            let (streams, _) = try await api.getFollowedStreams(limit: nil, after: nil)
            return streams
        }
    }

    var body: some View {
        switch self.data.data {
        case .success(let streams):
            self.success(streams)
        case .failure:
            Text("TODO: Failure")
        case .noData:
            Text("TODO: No data")
        }
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
        Button {
            self.data.reload()
        } label: {
            Text("Refresh")
        }
    }

    func buildImageUrl(using stream: Twitch.Stream) -> URL? {
        let url = stream.thumbnailURL.replacingOccurrences(of: "{width}", with: "960").replacingOccurrences(of: "{height}", with: "540")

        return URL(string: url)
    }
}

#Preview {
    FollowedStreamsView()
}
