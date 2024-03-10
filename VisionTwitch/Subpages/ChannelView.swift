//
//  ChannelView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/19/24.
//

import SwiftUI
import Twitch

struct ChannelView: View {
    @State private var loader = StandardDataLoader<User>()

    let channel: UserWrapper

    var body: some View {
        DataView(loader: self.$loader) { api, _ in
            switch self.channel {
            case .user(let user):
                return user
            case .id(let id):
                let users = try await api.getUsers(userIDs: [id])

                guard users.count > 0 else {
                    throw HelixError.requestFailed(error: "Could not fetch user", status: 200, message: "")
                }

                return users[0]
            }
        } content: { user in
            ChannelViewContent(channelUser: user)
        } loading: { _ in
            ProgressView()
        } error: { (_: HelixError?) in
            APIErrorView(loader: self.$loader)
        }
    }
}

struct ChannelViewContent: View {
    @Environment(\.openWindow) private var openWindow

    @State private var userLoader = StandardDataLoader<[Twitch.Stream]>()
    @State private var vodLoader = StandardDataLoader<([Video], String?)>()

    let channelUser: User

    var body: some View {
        VStack {
            HStack {
                self.profileImage
                VStack {
                    Text(self.channelUser.displayName)
                        .font(.title)
                        .lineLimit(1, reservesSpace: true)

                    DataView(loader: self.$userLoader) { api, _ in
                        let (streams, _) = try await api.getStreams(userIDs: [self.channelUser.id])
                        return streams
                    } content: { streams in
                        if let stream = streams.first {
                            Button {
                                openWindow(id: "stream", value: stream)
                            } label: {
                                Text("Watch Now")
                            }
                        } else {
                            Text("Offline")
                        }
                    } loading: { _ in
                        ProgressView()
                    } error: { (_: HelixError?) in
                        EmptyView()
                    }
                }
                Spacer()
            }
            .padding()
            AuthorizedStandardScrollableDataView(loader: self.$vodLoader, task: { api, _ in
                return try await api.getVideosByUserId(self.channelUser.id)
            }, noAuthMessage: "this channel's VoDs", noAuthSystemImage: Icon.channel) { videos, _ in
                VODGridView(videos: videos, onPaginationThresholdMet: self.onPaginationThresholdMet)
            }
            // Make profile image be pushed to the top
            Spacer()
        }
        .navigationTitle(self.channelUser.displayName)
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
    NavStack {
        ChannelViewContent(channelUser: USER_MOCK())
            .navigationTitle(USER_MOCK().displayName)
    }
}
