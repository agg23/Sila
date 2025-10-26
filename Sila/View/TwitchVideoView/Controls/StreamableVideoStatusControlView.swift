//
//  StreamStatusControlView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/25/24.
//

import SwiftUI
import Twitch

struct StreamableVideoStatusControlView: View {
    @State private var loader = StandardDataLoader<(User?, StreamableVideo?)>()

    let player: WebViewPlayer
    let streamableVideo: StreamableVideo

    var body: some View {
        DataView(loader: self.$loader, task: { api, _ in
            let task = self.createTask(requestStream: false, channelId: self.userId())
            return try await task(api)
        }, content: { user, stream in
            StreamableVideoStatusControlContentView(streamableVideo: stream ?? self.streamableVideo, user: user)
        }, loading: { data in
            StreamableVideoStatusControlContentView(streamableVideo: data?.1 ?? self.streamableVideo, user: data?.0)
        }, error: { (_: Error?) in
            StreamableVideoStatusControlContentView(streamableVideo: self.streamableVideo, user: nil)
        })
        .onChange(of: self.player.channelId, { oldValue, newValue in
            guard oldValue != nil, let newValue = newValue else {
                // If we're changing from (or to) an empty value, ignore it
                return
            }

            // TODO: Do we need to cancel this?
            Task {
                await self.loader.requestMore { _, apiAndUser in
                    let task = self.createTask(requestStream: true, channelId: newValue)
                    return try await task(apiAndUser.0)
                }
            }
        })
        .padding(6)
        .frame(width: 600, height: 80)
        .insetBackground()
        // 8 inner radius + 6 padding
        .clipShape(.rect(cornerRadius: 14))
    }

    func createTask(requestStream: Bool = false, channelId: String) -> (Helix) async throws -> (User?, StreamableVideo?) {
        return { api in
            async let usersAsync = await api.getUsers(userIDs: [channelId])

            if requestStream {
                async let streamsAsync = await api.getStreams(userIDs: [channelId])

                let (users, streams) = try await (usersAsync, streamsAsync)

                return (users.first, streams.0.first.map({ stream in .stream(stream) }))
            } else {
                let users = try await usersAsync

                return (users.first, nil)
            }
        }
    }

    func userId() -> String {
        switch self.streamableVideo {
        case .stream(let stream):
            return stream.userId
        case .video(let video):
            return video.userId
        }
    }
}

struct StreamableVideoStatusControlContentView: View {
    let streamableVideo: StreamableVideo
    let user: User?

    var body: some View {
        switch self.streamableVideo {
        case .stream(let stream):
            StreamableVideoStatusDisplayView(title: stream.title, userName: stream.userName, gameName: stream.gameName, profileImageUrl: self.profileImageUrl(), viewerCount: stream.viewerCount)
        case .video(let video):
            StreamableVideoStatusDisplayView(title: video.title, userName: video.userName, gameName: nil, profileImageUrl: self.profileImageUrl(), viewerCount: nil)
        }
    }

    func profileImageUrl() -> URL? {
        if let user = self.user {
            return URL(string: user.profileImageUrl)
        }

        return nil
    }
}

struct StreamableVideoStatusDisplayView: View {
    let title: String
    let userName: String
    let gameName: String?
    let profileImageUrl: URL?
    let viewerCount: Int?

    var body: some View {
        HStack(alignment: .top) {
            // TODO: This probably should show something other than clear in the error case
            LoadingAsyncImage(imageUrl: self.profileImageUrl, aspectRatio: 1.0, defaultColor: Color.clear)
                .clipShape(.rect(cornerRadius: 8))
            VStack(alignment: .leading) {
                Text(self.title)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Text(self.userName)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Text(self.gameName ?? "")
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .foregroundColor(.secondary)
            }
            Spacer()
            if let viewerCount = viewerCount {
                Image(systemName: Icon.viewerCount)
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.red, .white)
                Text(viewerCount.formatted(.number))
                    .padding(.trailing, 8)
            }
        }
    }
}

#Preview {
    StreamableVideoStatusControlView(player: WebViewPlayer(), streamableVideo: .stream(STREAM_MOCK()))
}

#Preview {
    StreamableVideoStatusControlView(player: WebViewPlayer(), streamableVideo: .video(VIDEO_MOCK()))
}
