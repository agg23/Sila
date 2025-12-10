//
//  SingleChannelQuery.swift
//  Sila
//
//  Created by Adam Gastineau on 12/6/25.
//

import AppIntents
import Twitch

// Enums need to be Codable even though there isn't a compile time error for this
// Not providing it has failures of the form:
// Error getting AppIntent from LNAction: AppIntent has missing parameter value for 'selectedChannel'. You may need to set a default value in the initializer of your @Parameter, or using the default method on your Query.
enum ChannelOption: AppEntity, Codable {
    case randomFollowed
    case literal(id: String, displayName: String, loginName: String)

    var id: String {
        switch self {
        case .randomFollowed:
            return "SILA_INTERNAL_RANDOM_FOLLOWED_ID"
        case .literal(id: let id, displayName: _, loginName: _):
            return id
        }
    }

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Channel")
    }

    var displayRepresentation: DisplayRepresentation {
        let displayName = switch self {
        case .randomFollowed:
            "Any followed channel"
        case .literal(id: _, displayName: let displayName, loginName: _):
            displayName
        }

        // Unfortunately images are fetched in a blocking matter, preventing the entire list from rendering
        // until all assets are downloaded, so we have to use only a title
        return DisplayRepresentation(title: LocalizedStringResource(stringLiteral: displayName))
    }

    static var defaultQuery = ChannelOptionListQuery()

    var channel: CurrentChannel? {
        switch self {
        case .randomFollowed:
            nil
        case .literal(id: let id, displayName: let displayName, loginName: let loginName):
            CurrentChannel(id: id, displayName: displayName, loginName: loginName)
        }
    }

    var debugName: String {
        switch self {
        case .randomFollowed:
            "Random"
        case .literal(id: _, displayName: let displayName, loginName: _):
            displayName
        }
    }
}

struct CurrentChannel {
    let id: String
    let displayName: String
    let loginName: String
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
        return [.randomFollowed]
            + (selectedChannels ?? []).map { .literal(id: $0.id, displayName: $0.name, loginName: $0.login) }
            + (otherChannels ?? [])
    }

    func entities(matching string: String) async throws -> [ChannelOption] {
        guard !string.isEmpty else {
            return try await self.suggestedEntities()
        }

        guard let api = self.authController.status.api() else {
            return []
        }

        do {
            let (channels, _) = try await api.helix(endpoint: .searchChannels(for: string))

            return [.randomFollowed] + channels.map { .literal(id: $0.id, displayName: $0.name, loginName: $0.login) }
        } catch {
            throw WidgetError.networkError
        }
    }

    func suggestedEntities() async throws -> [ChannelOption] {
        guard let api = self.authController.status.api() else {
            return []
        }

        do {
            if self.authController.isAuthorized() {
                let response = try await api.helix(endpoint: .getFollowedChannels(limit: 100))

                return [.randomFollowed] + response.follows.sorted {
                    $0.broadcasterName.lowercased() < $1.broadcasterName.lowercased()
                }.map {
                    .literal(id: $0.broadcasterID, displayName: $0.broadcasterName, loginName: $0.broadcasterLogin)
                }
            } else {
                let (streams, _) = try await api.helix(endpoint: .getStreams(limit: 20))

                return [.randomFollowed] + streams.map { .literal(id: $0.id, displayName: $0.userName, loginName: $0.userLogin) }
            }
        } catch {
            throw WidgetError.networkError
        }
    }
}
