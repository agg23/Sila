//
//  ChannelView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/19/24.
//

import SwiftUI
import Twitch

struct ChannelView: View {
    @State private var loader = DataLoader<User, AuthStatus>()

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

    @State private var userLoader = DataLoader<[Twitch.Stream], AuthStatus>()

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
                                openWindow(id: "channelVideo", value: stream.userName)
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
        }
        .navigationTitle(self.channelUser.displayName)
    }

    var profileImage: some View {
        LoadingAsyncImage(imageUrl: URL(string: self.channelUser.profileImageUrl), aspectRatio: 1.0)
            .frame(width: 150)
    }
}

#Preview {
    ChannelViewContent(channelUser: USER_MOCK())
}
