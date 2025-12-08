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
        let state = await self.fetchEntry(for: configuration, context: context)
        return ChannelPosterTimelineEntry(date: .now, state: state, intent: configuration, context: context)
    }

    func timeline(for configuration: Intent, in context: Context) async -> Timeline<Entry> {
        let refreshTime = Calendar.current.date(byAdding: .minute, value: 5, to: .now)!
        let entry = await self.snapshot(for: configuration, in: context)

        return Timeline(entries: [entry], policy: .after(refreshTime))
    }

    private func fetchEntry(for configuration: ChannelPosterConfigurationIntent, context: TimelineProviderContext) async -> Entry.State {
        // Preview must instantly return
        if context.isPreview {
            return .unconfigured(isPreview: true)
        }

        guard let selectedChannel = configuration.selectedChannel else {
            return .unconfigured(isPreview: false)
        }

        guard let api = AuthController().status.api() else {
            return .noData(displayName: selectedChannel.displayName)
        }

        async let usersAsync = try api.helix(endpoint: .getUsers(ids: [selectedChannel.id]))
        async let streamsAsync = try api.helix(endpoint: .getStreams(userIDs: [selectedChannel.id]))

        do {
            let (users, streams) = await (try usersAsync, try streamsAsync)

            guard let user = users.first else {
                return .noData(displayName: selectedChannel.displayName)
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

            return .data(ChannelPosterTimelineEntry.ChannelPosterData(displayName: selectedChannel.displayName, profileImage: profileImage, status: status))
        } catch {
            return .noData(displayName: selectedChannel.displayName)
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
