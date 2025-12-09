//
//  ChannelPosterWidget.swift
//  WidgetsExtension
//
//  Created by Adam Gastineau on 12/6/25.
//

import WidgetKit
import SwiftUI
import Twitch
import UIImageColors
import os.log

struct ChannelPosterWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "ChannelPosterWidget", intent: ChannelPosterConfigurationIntent.self, provider: ChannelPosterTimelineProvider()) { entry in
            let url: URL? = if let channel = entry.intent.selectedChannel {
                URL(string: "sila://watch?stream=\(channel.loginName)")
            } else {
                nil
            }

            ChannelPosterView(entry: entry)
                .widgetURL(url)
        }
        .configurationDisplayName("Channel Poster")
        .description("Displays the current live status of a selected or random followed Twitch channel.")
        // Small square, large square, portrait
        .supportedFamilies([.systemSmall, .systemLarge, .systemExtraLargePortrait])
        // The image has glare without using .paper
        .widgetTexture(.paper)
        .contentMarginsDisabled()
    }
}

fileprivate struct ChannelPosterTimelineProvider: AppIntentTimelineProvider {
    typealias Entry = ChannelPosterTimelineEntry
    typealias Intent = ChannelPosterConfigurationIntent

    func placeholder(in context: Context) -> Entry {
        ChannelPosterTimelineEntry(date: .now, state: .unconfigured(isPreview: true), intent: ChannelPosterConfigurationIntent(), context: context)
    }

    func snapshot(for configuration: Intent, in context: Context) async -> Entry {
        let previewMessage = context.isPreview ? " (Preview)" : ""
        os_log(.debug, "Fetching data for ChannelPosterWidget\(previewMessage): user \"\(configuration.selectedChannel?.loginName ?? "Unconfigured")\"")

        let state: Entry.State = if let selectedChannel = configuration.selectedChannel {
            await self.fetchEntry(selectedChannel)
        } else if context.isPreview {
            await self.fetchSnapshotEntry(for: configuration)
        } else {
            .unconfigured(isPreview: false)
        }

        os_log(.debug, "Fetched data for ChannelPosterWidget\(previewMessage): user \"\(configuration.selectedChannel?.loginName ?? "Unconfigured")\", state: \(state)")

        return ChannelPosterTimelineEntry(date: .now, state: state, intent: configuration, context: context)
    }

    func timeline(for configuration: Intent, in context: Context) async -> Timeline<Entry> {
        let refreshTime = Calendar.current.date(byAdding: .minute, value: 5, to: .now)!

        let entry = await self.snapshot(for: configuration, in: context)

        os_log(.debug, "Scheduling next data fetch for ChannelPosterWidget: user \"\(configuration.selectedChannel?.loginName ?? "Unconfigured")\" at \(refreshTime.description(with: .current))")

        return Timeline(entries: [entry], policy: .after(refreshTime))
    }

    private func fetchSnapshotEntry(for configuration: ChannelPosterConfigurationIntent) async -> Entry.State {
        // Choose random live followed channel, if it exists
        guard let api = AuthController().status.api() else {
            return .unconfigured(isPreview: true)
        }

        guard let liveStreams = try? await api.helix(endpoint: .getFollowedStreams(limit: 10)),
              let mostPopularStream = liveStreams.0.sorted(by: { $0.viewerCount > $1.viewerCount }).first else {
            return .unconfigured(isPreview: true)
        }

        return await self.fetchEntry(ChannelOption(id: mostPopularStream.userID, displayName: mostPopularStream.userName, loginName: mostPopularStream.userLogin))
    }

    private func fetchEntry(_ channel: ChannelOption?) async -> Entry.State {
        guard let channel = channel else {
            return .unconfigured(isPreview: false)
        }

        guard let api = AuthController().status.api() else {
            return .noData(displayName: channel.displayName)
        }

        async let usersAsync = try api.helix(endpoint: .getUsers(ids: [channel.id]))
        async let streamsAsync = try api.helix(endpoint: .getStreams(userIDs: [channel.id]))

        do {
            let (users, streams) = await (try usersAsync, try streamsAsync)

            guard let user = users.first else {
                return .noData(displayName: channel.displayName)
            }

            let image = await fetchImage(from: user.profileImageUrl)

            let profileImage = if let image = image {
                ProfileImage(image: image, colors: image.getColors() ?? UIImageColors.defaultColors)
            } else {
                ProfileImage(image: UIImage(imageLiteralResourceName: "SilaDummyProfileImage"), colors: UIImageColors.defaultColors)
            }

            let status = if let stream = streams.0.first {
                ChannelPosterTimelineEntry.ChannelPosterData.Status.online(stream.gameName, startedAt: stream.startedAt, viewerCount: stream.viewerCount)
            } else {
                ChannelPosterTimelineEntry.ChannelPosterData.Status.offline
            }

            return .data(ChannelPosterTimelineEntry.ChannelPosterData(displayName: channel.displayName, profileImage: profileImage, status: status))
        } catch {
            return .noData(displayName: channel.displayName)
        }
    }

    private func fetchImage(from urlString: String) async -> UIImage? {
        guard let url = URL(string: urlString) else {
            return nil
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return UIImage(data: data)
        } catch {
            print("Could not fetch image from url \(url): \(error)")
            return nil
        }
    }
}
