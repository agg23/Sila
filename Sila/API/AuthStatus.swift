//
//  AuthStatus.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/21/24.
//

import Foundation
import Twitch

enum AuthStatus {
    /// User is logged in
    case user(user: AuthUser, api: TwitchClient)
    /// No user is logged in, but with have public token
    case publicLoggedOut(api: TwitchClient)
    /// No access to Twitch API
    case none

    func api() -> TwitchClient? {
        guard let (api, _) = apiAndUser() else {
            return nil
        }

        return api
    }

    func user() -> AuthUser? {
        guard let (_, user) = apiAndUser() else {
            return nil
        }

        return user
    }

    func apiAndUser() -> (TwitchClient, AuthUser?)? {
        switch self {
        case .user(let user, let api):
            return (api, user)
        case .publicLoggedOut(let api):
            return (api, nil)
        case .none:
            return nil
        }
    }
}

extension AuthStatus: Equatable {
    public static func ==(lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.user(user: let lhsUser, api: _), .user(user: let rhsUser, api: _)):
            return lhsUser == rhsUser
        case (.publicLoggedOut, .publicLoggedOut):
            return true
        case (.none, .none):
            return true
        default:
            return false
        }
    }
}

struct AuthUser: Codable, Equatable {
    let id: String
    let username: String
    let avatarUrl: URL?
}
