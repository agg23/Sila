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
            Text("An error occurred")
        }
    }
}

struct ChannelViewContent: View {
    let channelUser: User

    var body: some View {
        VStack {
            HStack {
                self.profileImage
                VStack {
                    Text(self.channelUser.displayName)
                        .font(.title)
                        .lineLimit(1, reservesSpace: true)

                    let liveButton = Button {

                    } label: {
                        Text("Watch Now")
                    }

                    let offlineMessage = Text("Offline")

//                    SuccessDataView(taskClosure: { api in
//                        return Task {
//                            let (streams, _) = try await api.getStreams(userIDs: [user.id])
//                            return streams.count > 0
//                        }
//                    }, content: { isLive in
//                        if isLive {
//                            liveButton
//                        } else {
//                            offlineMessage
//                        }
//                    }, other: {
//                        offlineMessage
//                    }, requiresAuth: false)
                }
            }
        }
        .navigationTitle(self.channelUser.displayName)
        .onAppear {
            // This will trigger on every appear, refetching
//            liveProvider = DataProvider(taskClosure: { api in
//                Task {
//                    let (streams, _) = try await api.getStreams(userIDs: [user.id])
//                    return streams.count > 0
//                }
//            }, requiresAuth: false)
        }
    }

    var profileImage: some View {
        AsyncImage(url: URL(string: self.channelUser.profileImageUrl), content: { image in
            image
                .resizable()
        }, placeholder: {
            // Make sure ProgressView is the same size as the final image will be
            GeometryReader { geometry in
                ProgressView()
                    .frame(width: geometry.size.width, height: geometry.size.height)
            }
        })
        .aspectRatio(1.0, contentMode: .fit)
        .frame(width: 150)
    }
}

#Preview {
    ChannelView(channel: UserWrapper.user(USER_MOCK()))
}
