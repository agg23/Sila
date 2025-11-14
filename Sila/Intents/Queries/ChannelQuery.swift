//
//  ChannelQuery.swift
//  Sila
//
//  Created by Adam Gastineau on 3/18/24.
//

import AppIntents
import Twitch

// TODO: Unused
struct ChannelQuery: EntityStringQuery {
    @Dependency private var authController: AuthController

    func entities(matching string: String) async throws -> [ChannelEntity] {
        let api = try AuthShortcut.getAPI(self.authController)

        let (channels, _) = try await api.helix(endpoint: .searchChannels(for: string))

        return channels.map({ ChannelEntity(id: $0.id, loginName: $0.login, displayName: $0.name) })
    }

    func entities(for identifiers: [ChannelEntity.ID]) async throws -> [ChannelEntity] {
        guard identifiers.count > 0 else {
            return []
        }

        let api = try AuthShortcut.getAPI(self.authController)

        let channels = try await api.helix(endpoint: .getChannels(identifiers))

        return channels.map({ ChannelEntity(id: $0.id, loginName: $0.login, displayName: $0.name) })
    }

    func suggestedEntities() async throws -> [ChannelEntity] {
        let api = try AuthShortcut.getAPI(self.authController)

        if self.authController.isAuthorized() {
            let response = try await api.helix(endpoint: .getFollowedChannels(limit: 100))

            return response.follows.map({ ChannelEntity(id: $0.broadcasterID, loginName: $0.broadcasterLogin, displayName: $0.broadcasterName) })
        } else {
            // Public. Just return top streamers live now
            let (streams, _) = try await api.helix(endpoint: .getStreams(limit: 10))

            return streams.map({ ChannelEntity(id: $0.userID, loginName: $0.userLogin, displayName: $0.userName) })
        }
    }
}
