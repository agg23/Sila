//
//  Route.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/23/24.
//

import Foundation
import Twitch

enum Route: Equatable, Hashable, Codable {
    case category(game: GameWrapper)
    case channel(user: UserWrapper)
}

enum GameWrapper {
    case game(_ game: Game)
    case id(_ id: String)

    enum CodingKeys: String, CodingKey {
        case game
        case id
    }

    private struct InnerCodableGame: Codable {
        let id: String
        let name: String
        let boxArtUrl: String
        let igdbID: String

        init(from game: Game) throws {
            self.id = game.id
            self.name = game.name
            self.boxArtUrl = game.boxArtUrl
            self.igdbID = game.igdbID
        }

        func asGame() -> Game {
            Game(id: self.id, name: self.name, boxArtUrl: self.boxArtUrl, igdbID: self.igdbID)
        }
    }
}

// Game isn't encodable, so reimplement encode/decode protocols
extension GameWrapper: Codable {
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        var allKeys = ArraySlice(container.allKeys)
        guard let onlyKey = allKeys.popFirst(), allKeys.isEmpty else {
            throw DecodingError.typeMismatch(GameWrapper.self, DecodingError.Context.init(codingPath: container.codingPath, debugDescription: "Invalid number of keys found, expected one.", underlyingError: nil))
        }
        switch onlyKey {
        case .game:
            let game = try container.decode(InnerCodableGame.self, forKey: .game)
            self = .game(game.asGame())
        case .id:
            let id = try container.decode(String.self, forKey: .id)
            self = .id(id)
        }
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .game(let game):
            try container.encode(InnerCodableGame(from: game), forKey: .game)
        case .id(let id):
            try container.encode(id, forKey: .id)
        }
    }
}

extension GameWrapper: Hashable {
    func hash(into hasher: inout Hasher) {
        switch self {
        case .game(let game):
            hasher.combine("game")
            hasher.combine(game.id)
        case .id(let id):
            hasher.combine("id")
            hasher.combine(id)
        }
    }

    static func == (lhs: GameWrapper, rhs: GameWrapper) -> Bool {
        switch (lhs, rhs) {
        case (.game(let leftGame), .game(let rightGame)):
            return leftGame.id == rightGame.id
        case (.id(let leftId), .id(let rightId)):
            return leftId == rightId
        default:
            return false
        }
    }
}

enum UserWrapper {
    case user(_ user: User)
    case id(_ id: String)

    enum CodingKeys: String, CodingKey {
        case user
        case id
    }

    private struct InnerCodableUser: Codable {
        let id: String
        let login: String
        let displayName: String

        let type: String
        let broadcasterType: InnerCodableBroadcasterType

        let description: String
        let profileImageUrl: String
        let offlineImageUrl: String
        let createdAt: Date

        let email: String?

        init(from user: User) {
            self.id = user.id
            self.login = user.login
            self.displayName = user.displayName
            self.type = user.type
            self.broadcasterType = .init(from: user.broadcasterType)
            self.description = user.description
            self.profileImageUrl = user.profileImageUrl
            self.offlineImageUrl = user.offlineImageUrl
            self.createdAt = user.createdAt
            self.email = user.email
        }

        func asUser() -> User {
            .init(
                id: self.id,
                login: self.login,
                displayName: self.displayName,
                type: self.type,
                broadcasterType: self.broadcasterType.asBroadcasterType(),
                description: self.description,
                profileImageUrl: self.profileImageUrl,
                offlineImageUrl: self.offlineImageUrl,
                createdAt: self.createdAt,
                email: self.email
            )
        }
    }

    private enum InnerCodableBroadcasterType: String, Codable {
        case partner
        case affiliate
        case none = ""

        init(from broadcasterType: User.BroadcasterType) {
            switch broadcasterType {
            case .partner:
                self = .partner
            case .affiliate:
                self = .affiliate
            case .none:
                self = .none
            }
        }

        func asBroadcasterType() -> User.BroadcasterType {
            switch self {
            case .partner:
                return .partner
            case .affiliate:
                return .affiliate
            case .none:
                return .none
            }
        }
    }
}

extension UserWrapper: Codable {
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        var allKeys = ArraySlice(container.allKeys)
        guard let onlyKey = allKeys.popFirst(), allKeys.isEmpty else {
            throw DecodingError.typeMismatch(UserWrapper.self, DecodingError.Context.init(codingPath: container.codingPath, debugDescription: "Invalid number of keys found, expected one.", underlyingError: nil))
        }
        switch onlyKey {
        case .user:
            let user = try container.decode(User.self, forKey: .user)
            self = .user(user)
        case .id:
            let id = try container.decode(String.self, forKey: .id)
            self = .id(id)
        }
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .user(let user):
            try container.encode(InnerCodableUser(from: user), forKey: .user)
        case .id(let id):
            try container.encode(id, forKey: .id)
        }
    }
}

extension UserWrapper: Hashable {
    func hash(into hasher: inout Hasher) {
        switch self {
        case .user(let user):
            hasher.combine("user")
            hasher.combine(user.id)
        case .id(let id):
            hasher.combine("id")
            hasher.combine(id)
        }
    }

    static func == (lhs: UserWrapper, rhs: UserWrapper) -> Bool {
        switch (lhs, rhs) {
        case (.user(let leftUser), .user(let rightUser)):
            return leftUser.id == rightUser.id
        case (.id(let leftId), .id(let rightId)):
            return leftId == rightId
        default:
            return false
        }
    }
}
