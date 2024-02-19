//
//  StreamButtonView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/18/24.
//

import SwiftUI
import Twitch

struct StreamButtonView: View {
    @Environment(\.openWindow) private var openWindow;

    let stream: Twitch.Stream

    var body: some View {
        AsyncImageButton(imageUrl: buildImageUrl(using: self.stream), aspectRatio: 16.0/9.0) {
            openWindow(id: "channelVideo", value: stream.userName)
        } content: {
            VStack(alignment: .leading) {
                HStack {
                    Text(self.stream.gameName)
                    Spacer()
                    Text(self.stream.startedAt.formatted())
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)

                Text(self.stream.title)
                    .font(.title3)
                    .lineLimit(1)
                Text(self.stream.userName)
                    .truncationMode(.tail)
                    .lineLimit(1)

//                    tagList(stream.tags)
            }
        }
    }

    @ViewBuilder
    func tagList(_ list: [String]) -> some View {
        HStack {
            ForEach(list, id: \.self) { tag in
                TagView(text: tag)
            }
        }
    }

    func buildImageUrl(using stream: Twitch.Stream) -> URL? {
        let url = stream.thumbnailURL.replacingOccurrences(of: "{width}", with: "960").replacingOccurrences(of: "{height}", with: "540")

        return URL(string: url)
    }
}

#Preview {
    StreamButtonView(stream: STREAM_MOCK())
        .frame(width: 400, height: 300)
}
