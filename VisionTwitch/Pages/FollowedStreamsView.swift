//
//  FollowedStreamsView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/17/24.
//

import SwiftUI
import Twitch

struct FollowedStreamsView: View {
    @Environment(\.authController) private var authController

    @State private var channelsState: DataProvider<[Twitch.User], Error>? = DataProvider(taskClosure: { api in
        return Task {
            let (_, channels, _) = try await api.getFollowedChannels(limit: 100)

            let broadcasterIds = channels.map({$0.broadcasterId})

            let users = try await api.getUsers(userIDs: broadcasterIds)
            return users
        }
    }, requiresAuth: true)

    @DataLoader<[Twitch.Stream], AuthStatus> var liveStreamsLoader

    var body: some View {
        PickerTabView(leftTitle: "Live", leftView: {
            self.liveStreams
        }, rightTitle: "All Channels") {
            self.channels
        }
    }

    @ViewBuilder
    var liveStreams: some View {
        if self.authController.isAuthorized() {
            DataView2(loader: self.liveStreamsLoader, task: { (api, user) in
                guard user != nil else {
                    // If we have no user, we're unauthenticated and this is a buffered task
                    return []
                }
                print("Fetching")
                let (streams, _) = try await api.getFollowedStreams(limit: 100)
                return streams
            }, content: { streams in
                ScrollGridView {
                    StreamGridView(streams: streams)
                }
            }, loading: { _ in
                ProgressView()
            }, error: { (_: HelixError?) in
                Text("An error occured")
            })
        } else {
            Text("Not logged in")
        }
    }

    @ViewBuilder
    var channels: some View {
        DataView(provider: $channelsState, content: { users in
            ScrollGridView {
                ChannelGridView(channels: users)
            }
        }, error: { _ in
            Text("Error")
        }, requiresAuth: true)
    }
}
