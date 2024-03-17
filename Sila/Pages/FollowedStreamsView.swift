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
            #if VOD_ENABLED
            PickerTabView(leftTitle: "Live", leftView: {
                self.liveStreams
            }, rightTitle: "All Channels") {
                self.channels
            }
            #else
            self.liveStreams
            #endif
        } else {
            NeedsLoginView(noAuthMessage: "your followed streams", systemImage: Icon.following)
        }
    }

    @ViewBuilder
    var liveStreams: some View {
        AuthroizedStandardDataView(loader: self.$liveStreamsLoader, task: { api, user in
            print("Request live")
            guard user != nil else {
                // If we have no user, we're unauthenticated and this is a buffered task
                return ([], nil)
            }
            return try await api.getFollowedStreams(limit: 100)
        }, noAuthMessage: "your followed streams", noAuthSystemImage: Icon.following) { (streams, _) in
            if streams.isEmpty {
                EmptyDataView(title: "No Livestreams", systemImage: Icon.following, message: "live followed streams") {
                    Task {
                        try? await self.liveStreamsLoader.refresh()
                    }
                }
            } else {
                RefreshableScrollGridView(loader: self.liveStreamsLoader) {
                    StreamGridView(streams: streams, onPaginationThresholdMet: self.onPaginationThresholdMet)
                }
            }
        }
    }

    @ViewBuilder
    var channels: some View {
        // TODO: Does not support pagination, but I believe will fetch all 100 channels (probably all anyone has)
        AuthroizedStandardDataView(loader: self.$channelsLoader, task: { api, user in
            let (_, channels, _) = try await api.getFollowedChannels(limit: 100)

            let broadcasterIds = channels.map({$0.broadcasterId})

            let users = try await api.getUsers(userIDs: broadcasterIds)
            return users
        }, noAuthMessage: "your followed channels", noAuthSystemImage: Icon.following) { channels in
            if channels.isEmpty {
                EmptyDataView(title: "No Followed Channels", systemImage: Icon.following, message: "followed channels") {
                    Task {
                        try? await self.channelsLoader.refresh()
                    }
                }
            } else {
                RefreshableScrollGridView(loader: self.channelsLoader) {
                    ChannelGridView(channels: channels)
                }
            }
        }
    }

    func onPaginationThresholdMet() async {
        await self.liveStreamsLoader.requestMore { data, apiAndUser in
            guard let originalCusor = data.1 else {
                return data
            }

            let (newData, cursor) = try await apiAndUser.0.getFollowedStreams(limit: 100, after: originalCusor)

            return (data.0 + newData, cursor)
        }
    }
}
