//
//  ChannelTimelineProvider.swift
//  WidgetsExtension
//
//  Created by Adam Gastineau on 12/10/25.
//

import os.log
import UIKit
import WidgetKit
import AppIntents
import UIImageColors
import Twitch

struct ChannelTimelineProvider<T: ChannelConfigurationIntent>: AppIntentTimelineProvider {
    typealias Entry = ChannelTimelineEntry<T>
    typealias Intent = T

    func placeholder(in context: Context) -> Entry {
        ChannelTimelineEntry(date: .now, state: .unconfigured, intent: T(), context: context)
    }

    func snapshot(for configuration: Intent, in context: Context) async -> Entry {
        guard let snapshotEntry = await self.generateEntry(for: configuration, in: context) else {
            // We could not build an entry, say we're not configured
            return .init(date: .now, state: .unconfigured, intent: configuration, context: context)
        }

        return snapshotEntry
    }

    func timeline(for configuration: Intent, in context: Context) async -> Timeline<Entry> {
        let refreshTime = Calendar.current.date(byAdding: .minute, value: 5, to: .now)!

        let entry = await self.generateEntry(for: configuration, in: context)

        os_log(.debug, "Scheduling next data fetch for ChannelPosterWidget: user \"\(configuration.selectedChannel.debugName)\" at \(refreshTime.description(with: .current))")

        let entries: [Entry] = if let entry = entry {
            if case .noData(displayName: _) = entry.state {
                []
            } else {
                [entry]
            }
        } else {
            // We failed to fetch an entry, so don't update the widget
            []
        }

        return Timeline(entries: entries, policy: .after(refreshTime))
    }

    private func generateEntry(for configuration: T, in context: Context) async -> Entry? {
        let previewMessage = context.isPreview ? " (Preview)" : ""
        os_log(.debug, "Fetching data for ChannelPosterWidget\(previewMessage): user \"\(configuration.selectedChannel.debugName)\"")

        let state = if let channel = configuration.selectedChannel.channel {
            await self.fetchEntry(channel)
        } else {
            await self.fetchSnapshotEntry(for: configuration)
        }

        os_log(.debug, "Fetched data for ChannelPosterWidget\(previewMessage): user \"\(configuration.selectedChannel.debugName)\", state: \(state?.description ?? "nil")")

        if let state = state {
            return ChannelTimelineEntry(date: .now, state: state, intent: configuration, context: context)
        } else {
            return nil
        }
    }

    private func fetchSnapshotEntry(for configuration: T) async -> Entry.State? {
        // Choose random live followed channel, if it exists
        guard let api = AuthController().status.api() else {
            return .unconfigured
        }

        guard let liveStreams = try? await api.helix(endpoint: .getFollowedStreams(limit: 10)),
              let mostPopularStream = liveStreams.0.sorted(by: { $0.viewerCount > $1.viewerCount }).first else {
            return nil
        }

        return await self.fetchEntry(CurrentChannel(id: mostPopularStream.userID, displayName: mostPopularStream.userName, loginName: mostPopularStream.userLogin))
    }

    private func fetchEntry(_ channel: CurrentChannel) async -> Entry.State {
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
                ChannelTimelineEntry<T>.ChannelPosterData.Status.online(stream.gameName, streamTitle: stream.title, startedAt: stream.startedAt, viewerCount: stream.viewerCount)
            } else {
                ChannelTimelineEntry<T>.ChannelPosterData.Status.offline
            }

            return .data(ChannelTimelineEntry.ChannelPosterData(loginName: channel.loginName, displayName: channel.displayName, profileImage: profileImage, status: status))
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
