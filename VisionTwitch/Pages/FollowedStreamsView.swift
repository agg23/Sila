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

    @State private var liveStreamsLoader = StandardDataLoader<([Twitch.Stream], String?)>()
    @State private var channelsLoader = StandardDataLoader<[Twitch.User]>()

    var body: some View {
        // If statement to hide the picker when not authorized
        if self.authController.isAuthorized() {
            PickerTabView(leftTitle: "Live", leftView: {
                self.liveStreams
            }, rightTitle: "All Channels") {
                self.channels
            }
        } else {
            NeedsLoginView(noAuthMessage: "your followed streams")
        }
    }

    @ViewBuilder
    var liveStreams: some View {
        AuthorizedStandardScrollableDataView(loader: self.$liveStreamsLoader, task: { api, user in
            print("Request live")
            guard user != nil else {
                // If we have no user, we're unauthenticated and this is a buffered task
                return ([], nil)
            }
            return try await api.getFollowedStreams(limit: 100)
        }, noAuthMessage: "your followed streams") {
            await self.liveStreamsLoader.requestMore { data, apiAndUser in
                let (newData, cursor) = try await apiAndUser.0.getFollowedStreams(limit: 100, after: data.1)

                return (data.0 + newData, cursor)
            }
        } content: { (streams, _) in
            if streams.isEmpty {
                EmptyDataView(message: "live followed streams") {
                    Task {
                        try? await self.liveStreamsLoader.refresh()
                    }
                }
                // Fit it to the ScrollView
                .containerRelativeFrame(.vertical)
            } else {
                StreamGridView(streams: streams)
            }
        }
    }

    @ViewBuilder
    var channels: some View {
        // TODO: Does not support pagination, but I believe will fetch all 100 channels (probably all anyone has)
        AuthorizedStandardScrollableDataView(loader: self.$channelsLoader, task: { api, user in
            let (_, channels, _) = try await api.getFollowedChannels(limit: 100)

            let broadcasterIds = channels.map({$0.broadcasterId})

            let users = try await api.getUsers(userIDs: broadcasterIds)
            return users
        }, noAuthMessage: "your followed channels") { channels in
            if channels.isEmpty {
                EmptyDataView(message: "followed channels") {
                    Task {
                        try? await self.channelsLoader.refresh()
                    }
                }
                // Fit it to the ScrollView
                .containerRelativeFrame(.vertical)
            } else {
                ChannelGridView(channels: channels)
            }
        }
    }
}
