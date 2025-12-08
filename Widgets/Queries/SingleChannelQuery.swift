//
//  SingleChannelQuery.swift
//  Sila
//
//  Created by Adam Gastineau on 12/6/25.
//

import AppIntents
import Twitch

struct ChannelOption: AppEntity {
    let id: String
    let displayName: String
    let loginName: String

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Channel")
    }

    var displayRepresentation: DisplayRepresentation {
        // Unfortunately images are fetched in a blocking matter, preventing the entire list from rendering
        // until all assets are downloaded
        DisplayRepresentation(title: LocalizedStringResource(stringLiteral: displayName))
    }

    static var defaultQuery = ChannelOptionListQuery()
}

struct ChannelOptionListQuery: EntityStringQuery {
    let authController = AuthController()

    func entities(for identifiers: [ChannelOption.ID]) async throws -> [ChannelOption] {
        guard let api = self.authController.status.api() else {
            return []
        }

        async let selectedChannelsAsync = api.helix(endpoint: .getChannels(identifiers))
        async let otherChannelsAsync = self.suggestedEntities()

        let (selectedChannels, otherChannels) = await (try? selectedChannelsAsync, try? otherChannelsAsync)

        // TODO: The selectedChannels doesn't seem to work sometimes
        return (selectedChannels ?? []).map { channel in
            ChannelOption(
                id: channel.id,
                displayName: channel.name,
                loginName: channel.login,
            )
        } + (otherChannels ?? [])
    }

    func entities(matching string: String) async throws -> [ChannelOption] {
        guard !string.isEmpty else {
            return try await self.suggestedEntities()
        }

        guard let api = self.authController.status.api() else {
            return []
        }

        let (channels, _) = try await api.helix(endpoint: .searchChannels(for: string))

        return channels.map { channel in
            ChannelOption(
                id: channel.id,
                displayName: channel.name,
                loginName: channel.login,
            )
        }
    }

    func suggestedEntities() async throws -> [ChannelOption] {
        guard let api = self.authController.status.api() else {
            return []
        }

        if self.authController.isAuthorized() {
            let response = try await api.helix(endpoint: .getFollowedChannels(limit: 100))

            return response.follows.map { follow in
                ChannelOption(
                    id: follow.broadcasterID,
                    displayName: follow.broadcasterName,
                    loginName: follow.broadcasterLogin,
                )
            }.sorted { $0.displayName < $1.displayName }
        } else {
            let (streams, _) = try await api.helix(endpoint: .getStreams(limit: 20))

            return streams.map { stream in
                ChannelOption(
                    id: stream.userID,
                    displayName: stream.userName,
                    loginName: stream.userLogin,
                )
            }
        }

    }
}
