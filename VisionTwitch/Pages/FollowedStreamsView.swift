//
//  FollowedStreamsView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/17/24.
//

import SwiftUI
import Twitch

struct FollowedStreamsView: View {
    @State private var liveStreamsState: DataProvider<[Twitch.Stream], Error>? = DataProvider(taskClosure: { api in
        return Task {
            let (streams, _) = try await api.getFollowedStreams(limit: 100)
            return streams
        }
    }, requiresAuth: true)

    @State private var channelsState: DataProvider<[Twitch.User], Error>? = DataProvider(taskClosure: { api in
        return Task {
            let (_, channels, _) = try await api.getFollowedChannels(limit: 100)

            let broadcasterIds = channels.map({$0.broadcasterId})

            let users = try await api.getUsers(userIDs: broadcasterIds)
            return users
        }
    }, requiresAuth: true)

    var body: some View {
        PickerTabView(leftTitle: "Live", leftView: {
            self.liveStreams
        }, rightTitle: "All Channels") {
            self.channels
        }
    }

    @ViewBuilder
    var liveStreams: some View {
        DataView(provider: $liveStreamsState, content: { streams in
            ScrollGridView {
                StreamGridView(streams: streams)
            }
        }, error: { _ in
            Text("Error")
        }, requiresAuth: true)
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
