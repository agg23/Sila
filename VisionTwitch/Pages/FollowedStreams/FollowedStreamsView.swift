//
//  FollowedStreamsView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/17/24.
//

import SwiftUI
import Twitch

struct FollowedStreamsView: View {
    @StateObject var viewModel = FollowedStreamsModel()

    var body: some View {
        LazyHStack(content: {
            ForEach(self.viewModel.streams, id: \.id) { item in
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
        .onAppear {
            self.viewModel.fetchData()
        }
        Button {
            self.viewModel.fetchData()
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
