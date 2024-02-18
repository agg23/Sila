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
            FollowedStreamsDataView(streams: streams)
        }, error: { _ in
            Text("Error")
        })
    }
}

struct FollowedStreamsDataView: View {
    @Environment(\.openWindow) private var openWindow;

    let streams: [Twitch.Stream]

    var body: some View {
        LazyVGrid(columns: [
            GridItem(),
            GridItem(),
            GridItem(),
            GridItem()
        ], content: {
            ForEach(streams, id: \.id) { item in
                self.streamButton(item)
            }
        })
    }

    @ViewBuilder
    func streamButton(_ stream: Twitch.Stream) -> some View {
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
            .shadow(radius: 5)
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
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"

    return FollowedStreamsDataView(streams: [Twitch.Stream(id: "42322153657", userId: "22510310", userLogin: "gamesdonequick", userName: "GamesDoneQuick", gameID: "18808", gameName: "Resident Evil 5", type: "live", title: "Unapologetically Black and Fast 2024 - Resident Evil 5 speedrun by @Sprinkle_Theory and @SuperNamu !schedule !ubaf", language: "en", tags: ["English", "speedrun"], isMature: false, viewerCount: 2126, startedAt: dateFormatter.date(from: "2024-02-17 22:56:55 +0000")!, thumbnailURL: "https://static-cdn.jtvnw.net/previews-ttv/live_user_gamesdonequick-{width}x{height}.jpg"), Twitch.Stream(id: "40460498981", userId: "20786541", userLogin: "yogscast", userName: "Yogscast", gameID: "18846", gameName: "Garry\'s Mod", type: "live", title: "YogsCinema - Osie\'s Insane Life Stories | Gmod TTT XL", language: "en", tags: ["English", "NoBackseating", "Variety"], isMature: false, viewerCount: 199, startedAt: dateFormatter.date(from: "2024-02-17 22:56:55 +0000")!, thumbnailURL: "https://static-cdn.jtvnw.net/previews-ttv/live_user_yogscast-{width}x{height}.jpg"), Twitch.Stream(id: "50428025309", userId: "10217631", userLogin: "patty", userName: "Patty", gameID: "766571430", gameName: "HELLDIVERS 2", type: "live", title: "I\'M DOING MY PART", language: "en", tags: ["Bald", "Masculine", "GigaChad", "Nobackseating", "NoTipsJustSips", "NoNUTHIN", "English", "NoHints", "NoHelp", "NoHelpUnlessAsked"], isMature: true, viewerCount: 61, startedAt: dateFormatter.date(from: "2024-02-18 04:02:27 +0000")!, thumbnailURL: "https://static-cdn.jtvnw.net/previews-ttv/live_user_patty-{width}x{height}.jpg")])
}
