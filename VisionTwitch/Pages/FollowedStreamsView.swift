//
//  FollowedStreamsView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/17/24.
//

import SwiftUI

struct FollowedStreamsView: View {
    var body: some View {
        PickerTabView(leftTitle: "Live", leftView: {
            self.liveStreams
        }, rightTitle: "All Channels") {
            self.channels
        }
    }

    @ViewBuilder
    var liveStreams: some View {
        DataView(taskClosure: { api in
            return Task {
                let (streams, _) = try await api.getFollowedStreams(limit: 100)
                return streams
            }
        }, content: { streams in
            ScrollGridView {
                StreamGridView(streams: streams)
            }
        }, error: { _ in
            Text("Error")
        }, requiresAuth: true, runOnAppear: true)
    }

    @ViewBuilder
    var channels: some View {
        DataView(taskClosure: { api in
            return Task {
                let (_, channels, _) = try await api.getFollowedChannels(limit: 100)

                let broadcasterIds = channels.map({$0.broadcasterId})

                let users = try await api.getUsers(userIDs: broadcasterIds)
                return users
            }
        }, content: { users in
            ScrollGridView {
                ChannelGridView(channels: users)
            }
        }, error: { _ in
            Text("Error")
        }, requiresAuth: true, runOnAppear: true)
    }
}
