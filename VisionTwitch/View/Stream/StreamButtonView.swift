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
        Button {
            openWindow(id: "channelVideo", value: stream.userName)
        } label: {
            VStack {
                AsyncImage(url: buildImageUrl(using: stream), content: { image in
                    image
                        .resizable()
                }, placeholder: {
                    // Make sure ProgressView is the same size as the final image will be
                    GeometryReader { geometry in
                        ProgressView()
                            .frame(width: geometry.size.width, height: geometry.size.height)
                    }
                })
                    .aspectRatio(16.0/9.0, contentMode: .fit)
                VStack(alignment: .leading) {
                    HStack {
                        Text(stream.gameName)
                        Spacer()
                        Text(stream.startedAt.formatted())
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                    Text(stream.title)
                        .font(.title3)
                        .lineLimit(1)
                    Text(stream.userName)
                        .truncationMode(.tail)
                        .lineLimit(1)

//                    tagList(stream.tags)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
            .background(.thinMaterial)
            .hoverEffect()
            .cornerRadius(20)
        }
        .buttonStyle(.plain)
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
