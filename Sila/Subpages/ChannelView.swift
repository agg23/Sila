//
//  ChannelView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/19/24.
//

import SwiftUI
import Twitch

struct ChannelView: View {
    @State private var loader = StandardDataLoader<(User, Twitch.Stream?)>()

    let channel: UserWrapper

    var body: some View {
        StandardDataView(loader: self.$loader) { api, _ in
            switch self.channel {
            case .user(let user):
                let (streams, _) = try await api.getStreams(userIDs: [user.id])

                return (user, streams.first)
            case .id(let id):
                async let usersTask = api.getUsers(userIDs: [id])
                async let (streamsTask, _) = api.getStreams(userIDs: [id])

                let (users, streams) = try await (usersTask, streamsTask)

                guard users.count > 0 else {
                    throw HelixError.requestFailed(error: "Could not fetch user", status: 200, message: "")
                }

                return (users[0], streams.first)
            }
        } content: { (user, stream) in
            ChannelViewContent(channelUser: user, stream: stream)
        }
    }
}

struct ChannelViewContent: View {
    @Environment(\.openWindow) private var openWindow

    @State private var userLoader = StandardDataLoader<[Twitch.Stream]>()
    @State private var vodLoader = StandardDataLoader<([Video], String?)>()

    let channelUser: User
    let stream: Twitch.Stream?

    var body: some View {
        VStack {
            HStack {
                self.profileImage
                VStack {
                    Text(self.channelUser.displayName)
                        .font(.title)
                        .lineLimit(1, reservesSpace: true)

                    if let stream = self.stream {
                        Button {
                            HistoryStore.shared.addRecentStream(stream)
                            openWindow(id: Window.stream, value: stream)
                        } label: {
                            Text("Watch Now")
                        }
                    } else {
                        Text("Offline")
                    }
                }
                Spacer()
            }
            .padding()
            // TODO: Add "VoDs" title or similar to lower section
            AuthroizedStandardDataView(loader: self.$vodLoader, task: { api, _ in
                return try await api.getVideosByUserId(self.channelUser.id)
            }, noAuthMessage: "this channel's VoDs", noAuthSystemImage: Icon.channel) { videos, _ in
                RefreshableScrollGridView(loader: self.vodLoader) {
                    VODGridView(videos: videos, onPaginationThresholdMet: self.onPaginationThresholdMet)
                }
            }
            // Make profile image be pushed to the top
            Spacer()
        }
        .largeNavigationTitle(self.channelUser.displayName)
        .toolbar {
            ShareLink(item: URL(string: "https://twitch.tv/\(self.channelUser.login)")!)
        }
    }

    var profileImage: some View {
        LoadingAsyncImage(imageUrl: URL(string: self.channelUser.profileImageUrl), aspectRatio: 1.0)
            .frame(width: 150)
    }

    func onPaginationThresholdMet() async {
        await self.vodLoader.requestMore { data, apiAndUser in
            guard let originalCursor = data.1 else {
                return data
            }

            let newData = try await apiAndUser.0.getVideosByUserId(self.channelUser.id, after: originalCursor)
            return (data.0 + newData.0, newData.1)
        }
    }
}

#Preview {
    PreviewNavStack {
        ChannelViewContent(channelUser: USER_MOCK(), stream: nil)
            .navigationTitle(USER_MOCK().displayName)
    }
}
